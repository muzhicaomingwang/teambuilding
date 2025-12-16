import React, { useState } from 'react';
import { ClaudeService } from '../utils/claudeService';

const TeamBuildingAssistant = () => {
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState('');
  const [formData, setFormData] = useState({
    teamSize: '10',
    duration: '2 hours',
    budget: '500',
    preferences: ''
  });

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const generateIdeas = async () => {
    if (!formData.teamSize || !formData.duration || !formData.budget) {
      alert('Please fill in all required fields');
      return;
    }

    setLoading(true);
    setResult('');

    try {
      const preferences = formData.preferences ? formData.preferences.split(',').map(p => p.trim()) : [];
      const ideas = await ClaudeService.generateTeamBuildingIdeas(
        parseInt(formData.teamSize),
        formData.duration,
        parseInt(formData.budget),
        preferences
      );
      setResult(ideas);
    } catch (error) {
      alert('Error generating ideas: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="team-building-assistant">
      <h2>Team Building Assistant</h2>
      <p>Get personalized team building activity suggestions powered by Claude AI</p>

      <div className="input-form">
        <div className="form-group">
          <label>Team Size:</label>
          <input
            type="number"
            name="teamSize"
            value={formData.teamSize}
            onChange={handleInputChange}
            placeholder="e.g., 10"
          />
        </div>

        <div className="form-group">
          <label>Duration:</label>
          <input
            type="text"
            name="duration"
            value={formData.duration}
            onChange={handleInputChange}
            placeholder="e.g., 2 hours, half day"
          />
        </div>

        <div className="form-group">
          <label>Budget per person ($):</label>
          <input
            type="number"
            name="budget"
            value={formData.budget}
            onChange={handleInputChange}
            placeholder="e.g., 50"
          />
        </div>

        <div className="form-group">
          <label>Preferences (optional):</label>
          <input
            type="text"
            name="preferences"
            value={formData.preferences}
            onChange={handleInputChange}
            placeholder="e.g., outdoor, creative, no physical activities"
          />
        </div>

        <button onClick={generateIdeas} disabled={loading}>
          {loading ? 'Generating Ideas...' : 'Generate Team Building Ideas'}
        </button>
      </div>

      {result && (
        <div className="results">
          <h3>Suggested Activities</h3>
          <div className="result-content">
            <pre>{result}</pre>
          </div>
        </div>
      )}
    </div>
  );
};

export default TeamBuildingAssistant;