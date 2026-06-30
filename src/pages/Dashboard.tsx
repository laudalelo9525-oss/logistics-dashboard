import React, { useEffect, useState } from 'react'
import { computeTrailerCycleTimes, dailyThroughput, detectIdleBottlenecks } from '../lib/analytics'
import { supabase } from '../lib/supabaseClient'

export default function Dashboard(){
  const [kpis, setKpis] = useState({ trips:0, avgCycleHours:0, idleCount:0 })

  useEffect(()=>{
    async function load(){
      // fetch recent fleet status and deliveries (lightweight)
      const { data: fleet } = await supabase.from('fleet_status').select('*').limit(500)
      const { data: deliveries } = await supabase.from('deliveries').select('*').limit(500)
      const cycles = computeTrailerCycleTimes((fleet||[]).map(f=>({ trailer_id: f.trailer_id, status_text: f.status_text, status_timestamp: f.status_timestamp })))
      // compute avg cycle in hours
      const all = Object.values(cycles).flat()
      const avgMins = all.length? all.reduce((a,b)=>a+b,0)/all.length : 0
      const avgHours = avgMins/60
      const daily = dailyThroughput(deliveries || [])
      const trips = daily.reduce((a,b)=>a+(b as any).trips,0)
      const idle = detectIdleBottlenecks((fleet||[]).map(f=>({ trailer_id: f.trailer_id, status_text: f.status_text, status_timestamp: f.status_timestamp })), 24)
      setKpis({ trips, avgCycleHours: Number(avgHours.toFixed(2)), idleCount: idle.length })
    }
    load()
  },[])

  return (
    <div className="p-6">
      <h2 className="text-2xl font-bold">Dashboard</h2>
      <div className="mt-4 grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="p-4 bg-neutral-800 rounded">
          <div className="text-sm text-neutral-400">Today's Trips</div>
          <div className="text-3xl font-bold">{kpis.trips}</div>
        </div>
        <div className="p-4 bg-neutral-800 rounded">
          <div className="text-sm text-neutral-400">Avg Cycle (hrs)</div>
          <div className="text-3xl font-bold">{kpis.avgCycleHours}</div>
        </div>
        <div className="p-4 bg-neutral-800 rounded">
          <div className="text-sm text-neutral-400">Idle >24h</div>
          <div className="text-3xl font-bold text-red-500">{kpis.idleCount}</div>
        </div>
      </div>
    </div>
  )
}
