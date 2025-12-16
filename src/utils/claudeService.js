import Anthropic from '@anthropic-ai/sdk';

const anthropic = new Anthropic({
  apiKey: import.meta.env.VITE_ANTHROPIC_API_KEY,
  dangerouslyAllowBrowser: true // Only for development; consider a backend for production
});

export const ClaudeService = {
  async generateTeamBuildingIdeas(teamSize, duration, budget, preferences = []) {
    try {
      const response = await anthropic.messages.create({
        model: 'claude-3-sonnet-20240229',
        max_tokens: 1000,
        messages: [{
          role: 'user',
          content: `Please suggest ${teamSize > 10 ? '5-7' : '3-5'} team building activities for a team of ${teamSize} people.
          The activities should be suitable for ${duration} and fit within a budget of $${budget}.
          The team prefers: ${preferences.join(', ') || 'a mix of indoor and outdoor activities'}.

          For each activity, please provide:
          1. Name of the activity
          2. Brief description
          3. Estimated cost per person
          4. Duration
          5. Difficulty level (Easy/Medium/Hard)
          6. Materials needed (if any)

          Format the response as a clear, organized list.`
        }]
      });

      return response.content[0].text;
    } catch (error) {
      console.error('Error generating team building ideas:', error);
      throw new Error('Failed to generate team building ideas');
    }
  },

  async createCustomActivity(description, constraints = {}) {
    try {
      const response = await anthropic.messages.create({
        model: 'claude-3-sonnet-20240229',
        max_tokens: 800,
        messages: [{
          role: 'user',
          content: `Create a custom team building activity based on this description: "${description}"

          Constraints: ${JSON.stringify(constraints, null, 2)}

          Please provide:
          1. Activity name and theme
          2. Detailed instructions
          3. List of required materials
          4. Timeline for preparation and execution
          5. Tips for facilitation
          6. Expected outcomes and debrief questions`
        }]
      });

      return response.content[0].text;
    } catch (error) {
      console.error('Error creating custom activity:', error);
      throw new Error('Failed to create custom activity');
    }
  },

  async analyzeTeamDynamics(teamInfo) {
    try {
      const response = await anthropic.messages.create({
        model: 'claude-3-sonnet-20240229',
        max_tokens: 1200,
        messages: [{
          role: 'user',
          content: `Analyze team dynamics and recommend team building activities. Here's the team information:
          ${JSON.stringify(teamInfo, null, 2)}

          Please provide:
          1. Analysis of potential team dynamics challenges
          2. 3-5 recommended activities to address specific needs
          3. Long-term team building strategy
          4. Communication improvement suggestions
          5. Trust-building activities`
        }]
      });

      return response.content[0].text;
    } catch (error) {
      console.error('Error analyzing team dynamics:', error);
      throw new Error('Failed to analyze team dynamics');
    }
  }
};

export default ClaudeService;