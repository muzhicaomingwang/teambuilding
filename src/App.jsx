import React, { useState } from 'react'
import './App.css'
import TeamBuildingAssistant from './components/TeamBuildingAssistant'

function App() {
  const [count, setCount] = useState(0)

  return (
    <>
      <div>
        <h1>Team Building Assistant - 团建助手</h1>
        <p>Welcome to your team building management tool</p>

        {/* Activity Planning Section */}
        <div className="card">
          <h2>Activity Planning</h2>
          <TeamBuildingAssistant />
        </div>

        {/* Team Management Section */}
        <div className="card">
          <h2>Team Management</h2>
        </div>

        {/* Budget Tracking */}
        <div className="card">
          <h2>Budget Tracking</h2>
        </div>
      </div>
    </>
  )
}

export default App