"""Offline I/Q map validator. Standard library only; no PLC/network operations."""
import argparse
import csv
import json
import re
from pathlib import Path

REQUIRED = {'signal', 'plc_tag', 'kind', 'address', 'data_type', 'encoding'}
WIDTHS = {'byte': 8, 'int': 16, 'word': 16, 'dint': 32, 'dword': 32, 'real': 32}
PREFIX_WIDTH = {'B': 8, 'W': 16, 'D': 32}
ENCODINGS = {
    'bool': {'digital'}, 'byte': {'integer'},
    'int': {'integer', 'scaled_0_10v', 'scaled_bipolar_10v'},
    'word': {'integer', 'scaled_0_10v'},
    'dint': {'integer'}, 'dword': {'integer'}, 'real': {'real'},
}


def validate(path, input_bytes=None, output_bytes=None):
    errors, rows, occupied, names, tags = [], [], {}, {}, {}
    with Path(path).open(encoding='utf-8-sig', newline='') as handle:
        reader = csv.DictReader(handle)
        missing = REQUIRED - set(reader.fieldnames or [])
        if missing:
            return {'valid': False, 'row_count': 0, 'errors': ['Missing columns: ' + ', '.join(sorted(missing))]}
        for row_no, raw in enumerate(reader, 2):
            if None in raw:
                errors.append(f'Row {row_no}: too many CSV fields')
                continue
            row = {key: (value or '').strip() for key, value in raw.items()}
            rows.append(row)
            label = f'Row {row_no} ({row["signal"] or "unnamed"})'
            row_errors = []
            for key in sorted(REQUIRED):
                if not row[key]:
                    row_errors.append(f'{key} is empty')
            for field, seen in [('signal', names), ('plc_tag', tags)]:
                value = row[field].casefold()
                if value:
                    if value in seen:
                        row_errors.append(f'duplicate {field} with row {seen[value]}')
                    else:
                        seen[value] = row_no
            kind, dtype, encoding = row['kind'].lower(), row['data_type'].lower(), row['encoding'].lower()
            if kind not in {'sensor', 'actuator'}:
                row_errors.append('kind must be sensor or actuator')
            if dtype not in ENCODINGS:
                row_errors.append('unsupported data_type')
            elif encoding not in ENCODINGS[dtype]:
                row_errors.append(f'encoding {encoding!r} is incompatible with {dtype}')
            address = row['address'].upper()
            bit_match = re.fullmatch(r'%([IQ])(\d+)\.([0-7])', address)
            value_match = re.fullmatch(r'%([IQ])([BWD])(\d+)', address)
            span = None
            if bit_match:
                area, byte_no, bit_no = bit_match.groups()
                start = int(byte_no) * 8 + int(bit_no)
                span = (area, start, start + 1)
                if dtype != 'bool':
                    row_errors.append('bit address requires Bool')
            elif value_match:
                area, prefix, byte_no = value_match.groups()
                start = int(byte_no) * 8
                span = (area, start, start + PREFIX_WIDTH[prefix])
                if WIDTHS.get(dtype) != PREFIX_WIDTH[prefix]:
                    row_errors.append(f'%{area}{prefix} address width does not match {dtype}')
            else:
                row_errors.append('unsupported address; use %I0.0/%Q0.0, %IBn/%QBn, %IWn/%QWn or %IDn/%QDn')
            if span:
                area, start, end = span
                if kind in {'sensor', 'actuator'} and area != ('I' if kind == 'sensor' else 'Q'):
                    row_errors.append('sensor must map to I; actuator must map to Q')
                limit = input_bytes if area == 'I' else output_bytes
                if limit is not None and end > limit * 8:
                    row_errors.append(f'address exceeds supplied {area} range ({limit} bytes)')
                overlaps = sorted({prior_row for prior_start, prior_end, prior_row in occupied.get(area, [])
                                   if start < prior_end and prior_start < end})
                if overlaps:
                    row_errors.append('memory overlap with row(s) ' + ', '.join(map(str, overlaps)))
                occupied.setdefault(area, []).append((start, end, row_no))
            errors.extend(f'{label}: {message}' for message in row_errors)
    if not rows:
        errors.append('No mapping rows')
    return {
        'valid': not errors, 'row_count': len(rows), 'errors': errors,
        'ranges_checked': {'input_bytes': input_bytes, 'output_bytes': output_bytes},
        'not_checked': ['Actual driver offsets/counts and WORD/DWORD mode',
                        'CPU supported address range when no limit supplied',
                        'Scene tag existence, tag polarity, TIA compilation and live communication'],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('csv_path', type=Path)
    parser.add_argument('--input-bytes', type=int)
    parser.add_argument('--output-bytes', type=int)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    for value in (args.input_bytes, args.output_bytes):
        if value is not None and value <= 0:
            parser.error('range limits must be positive byte counts')
    try:
        report = validate(args.csv_path, args.input_bytes, args.output_bytes)
    except (OSError, UnicodeError, csv.Error) as exc:
        report = {'valid': False, 'row_count': 0, 'errors': [str(exc)]}
    text = json.dumps(report, ensure_ascii=False, indent=2)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text + '\n', encoding='utf-8')
    print(text)
    return 0 if report['valid'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
