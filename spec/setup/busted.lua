-- In-repo replacement for the external `faketorio` package.
-- Usage in a spec:  require('spec/setup/busted')()
local Env = require('spec/setup/factorio_env')
return function(opts)
    return Env.install(opts)
end
