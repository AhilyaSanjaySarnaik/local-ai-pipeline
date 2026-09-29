import json
import os
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../services/ai-api')))
from client import query_local_ai

def process_batch():
    config_path = "D:\\local-ai-pipeline\\config\\systems_manifest.json"
    if not os.path.exists(config_path):
        print("? Error: config/systems_manifest.json not found.")
        return

    with open(config_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    for target in data.get("infrastructure_targets", []):
        name = target["system_name"]
        scenario = target["scenario"]
        print(f"?? Processing automated batch item for: {name}...")
        
        prompt = f"Generate a detailed Disaster Recovery (DR) Runbook for SYSTEM: {name} experiencing SCENARIO: {scenario}. Break it down into Checklist, RCA, and Recovery Steps."
        response = query_local_ai(prompt, model='qwen3:4b')
        
        out_name = f"D:\\local-ai-pipeline\\projects\\{name.lower().replace(' ', '_')}_dr_plan.md"
        with open(out_name, "w", encoding="utf-8") as out_f:
            out_f.write(response)
        print(f"? Successfully generated and stored document at: {out_name}\n")

if __name__ == "__main__":
    process_batch()
