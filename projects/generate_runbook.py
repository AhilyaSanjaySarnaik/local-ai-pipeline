import sys
import os
import time
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../services/ai-api')))
from client import query_local_ai

def build_runbook(system_name, scenario):
    prompt = f"""
    Generate a detailed Disaster Recovery (DR) Runbook for:
    SYSTEM: {system_name}
    SCENARIO: {scenario}
    
    Structure the document clearly with sections for Response Checklist, Root Cause Analysis, Recovery steps, and Health Verification.
    """
    
    print(f"?? Contacting local Ollama instance for system: {system_name}...")
    print("? Processing heavy generation context... (Please do not close this window or hit Ctrl+C)")
    
    start_time = time.time()
    response = query_local_ai(prompt, model='qwen3:4b')
    elapsed = time.time() - start_time
    
    if "Error connecting" in response:
        print(f"? Generation failed: {response}")
        return

    output_path = f"D:\\local-ai-pipeline\\projects\\{system_name.lower().replace(' ', '_')}_dr_plan.md"
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(response)
    print(f"? Success! Runbook saved securely in {elapsed:.1f}s to: {output_path}")

if __name__ == "__main__":
    build_runbook("Database Cluster", "Complete Ransomware/Storage Corruption Failure")
