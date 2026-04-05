# AI Agent Tools Integration Guide

## Overview

This setup supports **OpenAI-compatible tool calling** for building autonomous AI agents using frameworks like **LangChain**, **CrewAI**, **AutoGPT**, and custom implementations.

## What are AI Agent Tools?

Tools (also called functions or plugins) allow LLMs to:
- Execute code and commands
- Access external APIs
- Search the web
- Read/write files
- Query databases
- Perform calculations

## Architecture

### OpenAI-Compatible Protocol

Both llama.cpp and vLLM implement the OpenAI `/v1/chat/completions` endpoint with tool calling support.

**Request Format:**
```json
{
  "model": "your-model",
  "messages": [
    {"role": "user", "content": "What's the weather in Paris?"}
  ],
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Get current weather for a city",
        "parameters": {
          "type": "object",
          "properties": {
            "city": {"type": "string"}
          }
        }
      }
    }
  ]
}
```

**Response:**
```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "tool_calls": [{
        "id": "call_123",
        "type": "function",
        "function": {
          "name": "get_weather",
          "arguments": "{\"city\": \"Paris\"}"
        }
      }]
    }
  }]
}
```

## Usage Modes

### 1. Chat Assistant (No Tools)

Simple conversation:

```python
import openai

client = openai.OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed"
)

response = client.chat.completions.create(
    model="your-model",
    messages=[
        {"role": "user", "content": "Hello!"}
    ]
)

print(response.choices[0].message.content)
```

### 2. AI Agent (With Tools)

Autonomous agent with function calling:

```python
import openai
import json

client = openai.OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed"
)

# Define tools
tools = [
    {
        "type": "function",
        "function": {
            "name": "search_web",
            "description": "Search the web for information",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search query"
                    }
                },
                "required": ["query"]
            }
        }
    }
]

# Actual function implementation
def search_web(query):
    # Your implementation
    return f"Search results for: {query}"

# Agent loop
messages = [{"role": "user", "content": "Find information about TurboQuant"}]

while True:
    response = client.chat.completions.create(
        model="your-model",
        messages=messages,
        tools=tools
    )

    message = response.choices[0].message
    messages.append(message)

    # Check if tool was called
    if message.tool_calls:
        for tool_call in message.tool_calls:
            function_name = tool_call.function.name
            arguments = json.loads(tool_call.function.arguments)

            # Execute function
            if function_name == "search_web":
                result = search_web(**arguments)

            # Add result to conversation
            messages.append({
                "role": "tool",
                "tool_call_id": tool_call.id,
                "content": result
            })
    else:
        # No more tools to call
        print(message.content)
        break
```

## Integration with Frameworks

### LangChain

```python
from langchain.chat_models import ChatOpenAI
from langchain.tools import tool
from langchain.agents import create_openai_tools_agent, AgentExecutor
from langchain_core.prompts import ChatPromptTemplate

# Connect to local LLM
llm = ChatOpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed",
    model="your-model"
)

# Define tools
@tool
def calculate(expression: str) -> str:
    """Evaluate a mathematical expression"""
    return str(eval(expression))

@tool
def get_time() -> str:
    """Get current time"""
    from datetime import datetime
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# Create agent
tools = [calculate, get_time]
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant."),
    ("human", "{input}"),
    ("placeholder", "{agent_scratchpad}"),
])

agent = create_openai_tools_agent(llm, tools, prompt)
agent_executor = AgentExecutor(agent=agent, tools=tools)

# Run
result = agent_executor.invoke({
    "input": "What's 25 * 17 and what time is it?"
})
print(result["output"])
```

### CrewAI

```python
from crewai import Agent, Task, Crew
from langchain.chat_models import ChatOpenAI

# Configure LLM
llm = ChatOpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed",
    model="your-model"
)

# Define agent
researcher = Agent(
    role="Research Analyst",
    goal="Find and analyze information",
    backstory="Expert researcher with attention to detail",
    llm=llm,
    tools=[search_web, read_file]  # Your custom tools
)

# Define task
task = Task(
    description="Research TurboQuant and summarize key points",
    agent=researcher
)

# Create crew
crew = Crew(
    agents=[researcher],
    tasks=[task]
)

# Execute
result = crew.kickoff()
print(result)
```

### AutoGen

```python
from autogen import AssistantAgent, UserProxyAgent

# Configure LLM
llm_config = {
    "config_list": [{
        "base_url": "http://localhost:8080/v1",
        "api_key": "not-needed",
        "model": "your-model"
    }]
}

# Create assistant
assistant = AssistantAgent(
    name="assistant",
    llm_config=llm_config
)

# Create user proxy (executes code)
user_proxy = UserProxyAgent(
    name="user_proxy",
    code_execution_config={"work_dir": "coding"}
)

# Start conversation
user_proxy.initiate_chat(
    assistant,
    message="Write Python code to calculate fibonacci(20)"
)
```

## Open WebUI Plugins

Open WebUI has built-in support for tools/plugins.

### Enable Tools

1. Open Open WebUI: http://localhost:3000
2. Go to Settings → Tools
3. Enable "Function Calling"

### Install Community Plugins

Popular plugins:
- **Web Search**: DuckDuckGo, Google
- **Calculator**: Math expressions
- **Weather**: Current weather data
- **Wikipedia**: Search Wikipedia
- **Code Execution**: Run Python/JavaScript

### Create Custom Plugin

Example plugin (`my_tool.py`):

```python
from typing import Optional
import requests

class Tools:
    def __init__(self):
        pass

    def get_crypto_price(
        self,
        symbol: str,
        __user__: dict = {}
    ) -> str:
        """
        Get cryptocurrency price
        :param symbol: Crypto symbol (e.g., BTC, ETH)
        """
        response = requests.get(
            f"https://api.coingecko.com/api/v3/simple/price",
            params={
                "ids": symbol.lower(),
                "vs_currencies": "usd"
            }
        )
        data = response.json()
        price = data[symbol.lower()]["usd"]
        return f"${price:,.2f}"
```

Install in Open WebUI:
1. Go to Settings → Tools → Add Tool
2. Upload `my_tool.py`
3. Tool becomes available to all models

## Advanced: Custom RPC Tools

Create tools that call services on remote machines.

### Example: RPC Tool for Strong PC

On weak PC, create tool that calls strong PC:

```python
import openai
import requests

# Connect to weak PC LLM
client = openai.OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed"
)

# Tool that uses strong PC for heavy computation
def heavy_analysis(data: str) -> str:
    """Use strong PC for intensive analysis"""
    response = requests.post(
        "http://192.168.1.200:8080/v1/chat/completions",
        json={
            "model": "large-model",
            "messages": [
                {"role": "user", "content": f"Analyze this: {data}"}
            ]
        }
    )
    return response.json()["choices"][0]["message"]["content"]

# Register as tool
tools = [{
    "type": "function",
    "function": {
        "name": "heavy_analysis",
        "description": "Use strong PC for complex analysis",
        "parameters": {
            "type": "object",
            "properties": {
                "data": {"type": "string"}
            }
        }
    }
}]

# Use in agent
response = client.chat.completions.create(
    model="local-model",
    messages=[
        {"role": "user", "content": "Analyze this complex dataset..."}
    ],
    tools=tools
)
```

## Tool Best Practices

### 1. Clear Descriptions

```python
# Good
"Search the web for current information about a topic"

# Bad
"Search"
```

### 2. Type Hints

```python
{
    "name": "calculate_age",
    "parameters": {
        "type": "object",
        "properties": {
            "birth_year": {
                "type": "integer",
                "description": "Year of birth (e.g., 1990)"
            }
        },
        "required": ["birth_year"]
    }
}
```

### 3. Error Handling

```python
def my_tool(param: str) -> str:
    try:
        # Tool logic
        return result
    except Exception as e:
        return f"Error: {str(e)}"
```

### 4. Timeout Protection

```python
import signal

def timeout_handler(signum, frame):
    raise TimeoutError("Tool execution timeout")

def safe_tool(param: str) -> str:
    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(30)  # 30 second timeout
    try:
        return actual_tool(param)
    finally:
        signal.alarm(0)
```

## Model Requirements

Not all models support tool calling well. Best models:

### Excellent Tool Support
- Qwen2.5 (7B, 14B, 32B, 72B)
- Llama 3.1 (8B, 70B, 405B)
- Mistral (7B v0.3+)

### Good Support
- Gemma 2 (9B, 27B)
- DeepSeek Coder V2
- Phi-3 (3.8B, 14B)

### Limited Support
- Llama 2 (basic only)
- Older models

## Testing Tools

### Simple Test Script

```python
import openai

client = openai.OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed"
)

tools = [{
    "type": "function",
    "function": {
        "name": "test_tool",
        "description": "A simple test tool",
        "parameters": {
            "type": "object",
            "properties": {
                "message": {"type": "string"}
            }
        }
    }
}]

response = client.chat.completions.create(
    model="your-model",
    messages=[
        {"role": "user", "content": "Call test_tool with message 'hello'"}
    ],
    tools=tools
)

print(response.choices[0].message)
```

## Resources

- **LangChain**: https://python.langchain.com/docs/modules/agents/
- **CrewAI**: https://docs.crewai.com/
- **AutoGen**: https://microsoft.github.io/autogen/
- **OpenAI Tools**: https://platform.openai.com/docs/guides/function-calling
- **Open WebUI Plugins**: https://docs.openwebui.com/tutorials/plugin/

## See Also

- [TurboQuant Paper](./turboquant-paper.md)
- [OpenVINO NPU Guide](./openvino-npu-guide.md)
