import sys
from ollama import Client

def query_local_ai(prompt, model='qwen3:4b', system_prompt=None):
    try:
        client = Client(host='http://localhost:11434')
        messages = []
        if system_prompt:
            messages.append({'role': 'system', 'content': system_prompt})
        messages.append({'role': 'user', 'content': prompt})
        
        response = client.chat(model=model, messages=messages)
        return response['message']['content']
    except Exception as e:
        return f'Error connecting to local AI pipeline: {str(e)}'

if __name__ == '__main__':
    # Safely merge all command line parameters into a single string query
    test_prompt = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else 'Confirm your operational status.'
    sys_instruction = "You are a local AI model running completely offline inside the user's custom architecture pipeline. Acknowledge your environment."
    print(query_local_ai(test_prompt, system_prompt=sys_instruction))
