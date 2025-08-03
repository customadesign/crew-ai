#!/usr/bin/env python
"""
CrewAI Web Application
A simple web interface for running CrewAI agents
"""

from flask import Flask, render_template, request, jsonify
from crewai import Agent, Crew, Process, Task
from dotenv import load_dotenv
import os
import logging
from datetime import datetime

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create Flask app
app = Flask(__name__)

@app.route('/')
def index():
    """Render the main page"""
    return render_template('index.html')

@app.route('/api/run-crew', methods=['POST'])
def run_crew():
    """API endpoint to run the crew with a custom task"""
    try:
        data = request.json
        task_description = data.get('task', 'Analyze the benefits of AI in modern business')
        
        logger.info(f"Running crew with task: {task_description}")
        
        # Create agent
        researcher = Agent(
            role="Senior Research Analyst",
            goal="Analyze and provide insights on topics",
            backstory="Expert analyst with years of experience in gathering and analyzing information.",
            verbose=True,
            allow_delegation=False
        )
        
        # Create task
        task = Task(
            description=task_description,
            expected_output="A detailed analysis report with key findings and recommendations",
            agent=researcher
        )
        
        # Create and run crew
        crew = Crew(
            agents=[researcher],
            tasks=[task],
            verbose=True,
            process=Process.sequential
        )
        
        # Execute crew
        result = crew.kickoff()
        
        return jsonify({
            'success': True,
            'result': str(result),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error running crew: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)