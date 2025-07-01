function lift_getset(get, set!, obstriggers...)
    tgtobs = Observable(get())
    selfupdating = Ref(0)
    onany(obstriggers...) do _...
        selfupdating[] += 1
        tgtobs[] = get()
        selfupdating[] -= 1
    end
    on(tgtobs) do v
        if selfupdating[] == 0
            set!(v)
        end
    end
    return tgtobs
end

function obs_getset(obs_get, obs_set)
    obs = typeof(obs_get)(obs_get[])
    selfupdating = Ref(0)
    on(obs_get) do v
        selfupdating[] += 1
        obs[] = v
        selfupdating[] -= 1
    end
    on(obs) do v
        if selfupdating[] == 0
            obs_set[] = v
        end
    end
    return obs
end
