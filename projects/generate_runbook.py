import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
# Injected folder navigation to bypass the folder hyphen issue
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../services/ai-api')))
from client import query_local_ai

def build_runbook(system_name, scenario):
    prompt = f"""
    Generate a detailed Disaster Recovery (DR) Runbook for:
    SYSTEM: {system_name}
    SCENARIO: {scenario}
    
    Structure the document clearly with sections for Response Checklist, Root Cause Analysis, Recovery steps, and Health Verification.
    """
    
    print(f"Generating DR Runbook for {system_name}...")
    response = query_local_ai(prompt, model='qwen3:4b')
    
    output_path = f"D:\\local-ai-pipeline\\projects\\{system_name.lower().replace(' ', '_')}_dr_plan.md"
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(response)
    print(f"Success! Runbook saved securely to: {output_path}")

if __name__ == "__main__":
    build_runbook("Database Cluster", "Complete Ransomware/Storage Corruption Failure")
