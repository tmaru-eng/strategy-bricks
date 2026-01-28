import argparse
import json
from pathlib import Path


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    for enc in ("utf-16", "utf-16-le", "utf-8", "cp932"):
        try:
            return raw.decode(enc)
        except Exception:
            continue
    return raw.decode("utf-16", errors="ignore")


def main() -> int:
    parser = argparse.ArgumentParser(description="Summarize MT5 tester log block evaluation.")
    parser.add_argument("--log", required=True, help="Path to tester log file")
    parser.add_argument("--config", required=True, help="Path to config json file")
    parser.add_argument("--json", dest="json_out", help="Output JSON summary path")
    parser.add_argument("--text", dest="text_out", help="Output text summary path")
    args = parser.parse_args()

    log_path = Path(args.log)
    config_path = Path(args.config)
    if not log_path.exists():
        print(f"ERROR: log not found: {log_path}")
        return 1
    if not config_path.exists():
        print(f"ERROR: config not found: {config_path}")
        return 1

    config_name = config_path.name
    needle = f"InpConfigPath=strategy/{config_name}"

    text = read_text(log_path)
    lines = text.splitlines()
    indices = [i for i, l in enumerate(lines) if needle in l]
    if not indices:
        print(f"ERROR: InpConfigPath not found for {config_name} in log")
        return 1

    start_idx = indices[-1]
    tail = lines[start_idx:]

    # Parse config
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        print(f"ERROR: invalid config json: {config_path} ({exc})")
        return 1
    expected_blocks = [b.get("id") for b in config.get("blocks", []) if b.get("id")]

    # Parse log events
    block_stats = {}
    errors = []
    config_loaded = None

    for line in tail:
        if "CONFIG_ERROR" in line:
            errors.append(line.strip())
        if "ConfigLoader: Loaded" in line and config_loaded is None:
            config_loaded = line.strip()
        if '"event":"BLOCK_EVAL"' not in line:
            continue
        brace = line.find("{")
        if brace < 0:
            continue
        json_str = line[brace:]
        try:
            event = json.loads(json_str)
        except Exception:
            continue
        block_id = event.get("blockId")
        type_id = event.get("typeId")
        status = event.get("status", "UNKNOWN")
        if not block_id:
            continue
        if block_id not in block_stats:
            block_stats[block_id] = {
                "typeId": type_id,
                "total": 0,
                "status": {}
            }
        block_stats[block_id]["total"] += 1
        block_stats[block_id]["status"][status] = block_stats[block_id]["status"].get(status, 0) + 1

    observed_blocks = set(block_stats.keys())
    missing_blocks = sorted(set(expected_blocks) - observed_blocks)
    unexpected_blocks = sorted(observed_blocks - set(expected_blocks))

    summary = {
        "config": str(config_path),
        "log": str(log_path),
        "config_loaded_line": config_loaded,
        "expected_block_count": len(expected_blocks),
        "evaluated_block_count": len(observed_blocks),
        "missing_blocks": missing_blocks,
        "unexpected_blocks": unexpected_blocks,
        "block_stats": block_stats,
        "errors": errors,
    }

    lines_out = []
    lines_out.append(f"Config: {config_name}")
    lines_out.append(f"Log: {log_path}")
    if config_loaded:
        lines_out.append(f"ConfigLoader: {config_loaded}")
    lines_out.append(f"Blocks in config: {len(expected_blocks)}")
    lines_out.append(f"Blocks evaluated: {len(observed_blocks)}")
    lines_out.append(f"Blocks missing: {len(missing_blocks)}")
    if missing_blocks:
        lines_out.append("Missing blockIds:")
        for bid in missing_blocks:
            lines_out.append(f"  - {bid}")
    if unexpected_blocks:
        lines_out.append("Unexpected blockIds (not in config):")
        for bid in unexpected_blocks:
            lines_out.append(f"  - {bid}")
    if errors:
        lines_out.append("Errors:")
        for err in errors[:10]:
            lines_out.append(f"  - {err}")

    output_text = "\n".join(lines_out)
    print(output_text)

    if args.text_out:
        Path(args.text_out).write_text(output_text + "\n", encoding="utf-8")
    if args.json_out:
        Path(args.json_out).write_text(json.dumps(summary, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
