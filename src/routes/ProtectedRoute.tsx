import React from 'react'
import { useAuth } from '../lib/useAuth'

export function ProtectedRoute({ allowedRoles, children }:{ allowedRoles: string[], children: React.ReactNode }){
  const { user, profile } = useAuth()

  if(!user) return <div className="p-6">Please sign in to continue.</div>
  if(!profile) return <div className="p-6">Loading profile…</div>
  if(!allowedRoles.includes(profile.role)) return <div className="p-6 text-yellow-300">You do not have access to this page.</div>

  return <>{children}</>
}
