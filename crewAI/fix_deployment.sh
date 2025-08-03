#!/bin/bash

# CrewAI Deployment Fix Script
# This script fixes the indentation issues and completes the deployment

echo "==================================="
echo "CrewAI Deployment Fix Script"
echo "==================================="

# SSH connection details
DROPLET_IP="64.227.99.12"
SSH_USER="root"

# Create a properly formatted example_crew.py file locally
cat > /tmp/example_crew.py << 'EOF'
#!/usr/bin/env python
from crewai import Agent, Crew, Process, Task
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

print("Starting CrewAI Example...")
print("=" * 50)

# Create a simple research agent
researcher = Agent(
    role="Senior Research Analyst",
    goal="Analyze and provide insights on topics",
    backstory="""You are an expert research analyst with years of experience
    in gathering and analyzing information to provide valuable insights.""",
    verbose=True,
    allow_delegation=False
)

# Create a research task
research_task = Task(
    description="Analyze the benefits of AI in modern business operations",
    expected_output="A detailed analysis report with key findings and recommendations",
    agent=researcher
)

# Create and run the crew
crew = Crew(
    agents=[researcher],
    tasks=[research_task],
    verbose=True,
    process=Process.sequential
)

if __name__ == "__main__":
    try:
        result = crew.kickoff()
        print("\n" + "=" * 50)
        print("Crew work complete!")
        print("=" * 50)
        print(result)
    except Exception as e:
        print(f"Error running crew: {e}")
        import traceback
        traceback.print_exc()
EOF

echo "✓ Created fixed example_crew.py locally"

# Copy the fixed file to the droplet and run deployment commands
ssh ${SSH_USER}@${DROPLET_IP} << 'REMOTE_COMMANDS'
echo "Connected to DigitalOcean Droplet"

cd /root/crewai-app/crewAI

# Backup existing file if it exists
if [ -f example_crew.py ]; then
    cp example_crew.py example_crew.py.backup
    echo "✓ Backed up existing example_crew.py"
fi

# Create the corrected example_crew.py file
cat > example_crew.py << 'EOF'
#!/usr/bin/env python
from crewai import Agent, Crew, Process, Task
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

print("Starting CrewAI Example...")
print("=" * 50)

# Create a simple research agent
researcher = Agent(
    role="Senior Research Analyst",
    goal="Analyze and provide insights on topics",
    backstory="""You are an expert research analyst with years of experience
    in gathering and analyzing information to provide valuable insights.""",
    verbose=True,
    allow_delegation=False
)

# Create a research task
research_task = Task(
    description="Analyze the benefits of AI in modern business operations",
    expected_output="A detailed analysis report with key findings and recommendations",
    agent=researcher
)

# Create and run the crew
crew = Crew(
    agents=[researcher],
    tasks=[research_task],
    verbose=True,
    process=Process.sequential
)

if __name__ == "__main__":
    try:
        result = crew.kickoff()
        print("\n" + "=" * 50)
        print("Crew work complete!")
        print("=" * 50)
        print(result)
    except Exception as e:
        print(f"Error running crew: {e}")
        import traceback
        traceback.print_exc()
EOF

echo "✓ Created fixed example_crew.py on droplet"

# Verify the file has no leading spaces
echo "Verifying file format..."
if head -n 1 example_crew.py | grep -q '^#!/usr/bin/env python$'; then
    echo "✓ File format verified - no leading spaces"
else
    echo "⚠ Warning: File may still have formatting issues"
fi

# Update Dockerfile to run the example
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire project
COPY . .

# Create directories
RUN mkdir -p /app/logs /app/data

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Install the package
RUN pip install -e .

# Run the example crew
CMD ["python", "example_crew.py"]
EOF

echo "✓ Updated Dockerfile"

# Check if .env file exists and has the correct keys
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    if [ -f .env.template ]; then
        cp .env.template .env
    else
        cat > .env << 'ENV_FILE'
# OpenAI API Key (required)
# Get your key from: https://platform.openai.com/api-keys
OPENAI_API_KEY=your_openai_api_key_here

# Serper API Key (optional - for web search)
# Get your key from: https://serper.dev/
SERPER_API_KEY=your_serper_api_key_here
ENV_FILE
    fi
    echo "⚠ WARNING: Please update the .env file with your actual API keys"
    echo "Edit the file with: nano .env"
fi

echo ""
echo "==================================="
echo "Rebuilding Docker container..."
echo "==================================="

# Stop existing container if running
docker-compose down 2>/dev/null || true

# Rebuild the container
docker-compose build --no-cache

echo ""
echo "==================================="
echo "Starting CrewAI application..."
echo "==================================="

# Start the container
docker-compose up -d

# Wait a moment for container to start
sleep 3

# Check container status
if docker ps | grep -q crewai-app; then
    echo "✓ Container is running"
    echo ""
    echo "Checking logs..."
    docker-compose logs --tail=20
else
    echo "⚠ Container failed to start"
    echo "Checking logs for errors..."
    docker-compose logs --tail=50
fi

echo ""
echo "==================================="
echo "Deployment Status"
echo "==================================="
echo "• Container Name: crewai-app"
echo "• Status: $(docker ps --filter name=crewai-app --format 'table {{.Status}}' | tail -n 1)"
echo ""
echo "Next steps:"
echo "1. Update .env file with your OpenAI API key: nano .env"
echo "2. Restart the container: docker-compose restart"
echo "3. View logs: docker-compose logs -f"
echo "4. Stop container: docker-compose down"

REMOTE_COMMANDS

echo ""
echo "==================================="
echo "Local Script Complete"
echo "==================================="
echo "To manually connect to your droplet:"
echo "ssh root@${DROPLET_IP}"
echo ""
echo "To update the OpenAI API key:"
echo "1. SSH into droplet: ssh root@${DROPLET_IP}"
echo "2. Navigate to app: cd /root/crewai-app/crewAI"
echo "3. Edit .env file: nano .env"
echo "4. Add your key: OPENAI_API_KEY=sk-..."
echo "5. Save and exit: Ctrl+X, Y, Enter"
echo "6. Restart container: docker-compose restart"