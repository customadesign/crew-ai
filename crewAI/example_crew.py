#!/usr/bin/env python
"""
Example CrewAI Application
This demonstrates how to create and run a simple crew
"""

from crewai import Agent, Crew, Process, Task
from crewai.tools import SerperDevTool
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Create agents
researcher = Agent(
    role="Senior Research Analyst",
    goal="Uncover cutting-edge developments in AI",
    backstory="""You work at a leading tech think tank.
    Your expertise lies in identifying emerging trends.
    You have a knack for dissecting complex data and presenting
    actionable insights.""",
    verbose=True,
    allow_delegation=False,
    tools=[SerperDevTool()]
)

writer = Agent(
    role="Tech Content Strategist",
    goal="Craft compelling content on tech advancements",
    backstory="""You are a renowned Content Strategist,
    known for your insightful and engaging articles.
    You transform complex concepts into compelling narratives.""",
    verbose=True,
    allow_delegation=True
)

# Create tasks
task1 = Task(
    description="""Conduct a comprehensive analysis of the latest advancements in AI.
    Identify key trends, breakthrough technologies, and potential industry impacts.""",
    expected_output="Full analysis report in bullet points",
    agent=researcher
)

task2 = Task(
    description="""Using the insights provided, develop an engaging blog
    post that highlights the most significant AI advancements.
    Your post should be informative yet accessible, catering to a tech-savvy audience.
    Make it sound cool, avoid complex words so it doesn't sound like AI.""",
    expected_output="Full blog post of at least 4 paragraphs",
    agent=writer
)

# Instantiate your crew with a sequential process
crew = Crew(
    agents=[researcher, writer],
    tasks=[task1, task2],
    verbose=2,
    process=Process.sequential
)

if __name__ == "__main__":
    print("Starting CrewAI Example...")
    print("=" * 50)
    
    # Get the crew to work!
    result = crew.kickoff()
    
    print("\n" + "=" * 50)
    print("Crew work complete!")
    print("=" * 50)
    print(result)