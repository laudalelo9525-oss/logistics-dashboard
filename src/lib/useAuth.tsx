import React, { createContext, useContext, useEffect, useState } from 'react'
import { supabase } from './supabaseClient'

type UserProfile = { id:string, email:string, role:string } | null

const AuthContext = createContext<{ user: any, profile: UserProfile } | undefined>(undefined)

export const AuthProvider: React.FC<{children:React.ReactNode}> = ({children}) =>{
  const [user,setUser] = useState<any>(null)
  const [profile,setProfile] = useState<UserProfile>(null)

  useEffect(()=>{
    const session = supabase.auth.getSession().then(r=>{
      if(r.data.session) setUser(r.data.session.user)
    })
    const { data: listener } = supabase.auth.onAuthStateChange((event, session) =>{
      setUser(session?.user ?? null)
      // fetch profile when logged in
      if(session?.user?.id){
        supabase.from('users').select('id,email,role').eq('id', session.user.id).single().then(res=>{
          if(res.data) setProfile(res.data as UserProfile)
        })
      } else {
        setProfile(null)
      }
    })
    return ()=>{
      listener?.subscription.unsubscribe()
    }
  },[])

  return <AuthContext.Provider value={{ user, profile }}>{children}</AuthContext.Provider>
}

export const useAuth = ()=>{
  const ctx = useContext(AuthContext)
  if(!ctx) throw new Error('useAuth must be used inside AuthProvider')
  return ctx
}
