local ipairs = ipairs

local versions = {
    { major = 0, minor =  8, bug_fix = 0, },
}

local return_val = {}
for _, version in ipairs(versions) do
    return_val[version] = require(
        "migrations"
        .. "." .. version.major
        .. "-" .. version.minor
        .. "-" .. version.bug_fix
    )
end

return return_val