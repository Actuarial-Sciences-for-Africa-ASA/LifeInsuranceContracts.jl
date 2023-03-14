push!(LOAD_PATH, "src");
import Base: @kwdef
using Pkg
Pkg.activate(".")
Pkg.instantiate()
using Test
using LifeInsuranceDataModel
using LifeInsuranceProduct
using BitemporalPostgres
using SearchLight
# using SearchLightPostgreSQL
# using TimeZones
# using ToStruct
# using JSON
# purging the data model entirely - empty the schema

# if (haskey(ENV, "GITPOD_REPO_ROOT"))
#     run(```psql -f sqlsnippets/droptables.sql```)
# elseif (haskey(ENV, "GENIE_ENV") & (ENV["GENIE_ENV"] == "dev"))
#     run(```psql -d postgres -f sqlsnippets/droptables.sql```)
# end

get_tariff_interface(Val(0))