module LifeInsuranceContracts
using LifeInsuranceDataModel, LifeInsuranceProduct, BitemporalPostgres, SearchLight, JSON
using Dates, TimeZones
import LifeInsuranceDataModel: connect, get_contracts, get_partners, get_products
import SearchLight: Serializer.serialize, Serializer.deserialize
export connect, get_contracts, get_partners, get_products,
    serialize, deserialize,
    create_component!, update_component!, update_entity!, commit_workflow!, rollback_workflow!, get_revision, MaxDate, ValidityInterval, Workflow,
    persistModelStateContract,
    get_revision, ContractPartnerRole, TariffItemRole, TariffItemPartnerRole,
    Contract, Partner, PartnerRevision, Product, Tariff,
    ContractSection, PartnerSection, ProductItemSection, TariffItemSection, ProductSection, TariffSection,
    csection, psection, pisection, prsection, tsection,
    get_contracts, get_partners, partner_ids, get_products, history_forest,
    get_tariff_interface, persist_tariffs, compareModelStateContract, compareRevisions, convert, get_node_by_label, load_role




tariffs = Dict{Integer,Integer}

function persist_tariffs()
    LifeInsuranceDataModel.connect()

    map(1:4) do tif_id
        tif = get_tariff_interface(Val(tif_id))
        (tif_id => create_tariff(tif.description,
            tif_id, tif.mortality_table, serialize(tif.parameters)))
    end
end

"""
function definitions
"""

"""
convert(node::BitemporalPostgres.Node)::Dict{String,Any}

provides the view for the history forest from tree data the contracts/partnersModel delivers
"""
function convert(node::BitemporalPostgres.Node)::Dict{String,Any}
    i = Dict(string(fn) => getfield(getfield(node, :interval), fn) for fn in fieldnames(ValidityInterval))
    shdw = length(node.shadowed) == 0 ? [] : map(node.shadowed) do child
        convert(child)
    end
    Dict("version" => string(i["ref_version"]), "interval" => i, "children" => shdw, "icon" => (i["is_committed"] == 1 ? "done" : "pending"), "label" => (i["is_committed"] == 1 ? "committed " : "pending ") * string(i["tsdb_validfrom"]) * " valid as of " * string(Date(i["tsworld_validfrom"], UTC)))
end


"""
get_node_by_label
retrieves a history node from its label 
"""

function get_node_by_label(ns::Vector{Dict{String,Any}}, lbl::String)
    for n in ns
        if (n["version"] == lbl)
            return (n)
        else
            if (length(n["children"]) > 0)
                m = get_node_by_label(n["children"], lbl)
                if !isnothing((m))
                    return m
                end
            end
        end
    end
end

"""
compareRevisions(t, previous::Dict{String,Any}, current::Dict{String,Any}) where {T<:BitemporalPostgres.ComponentRevision}
compare corresponding revision elements and return nothing if equal a pair of both else
"""
function compareRevisions(t, previous::Dict{String,Any}, current::Dict{String,Any})
    let changed = false
        for (key, previous_value) in previous
            if !(key in ("ref_validfrom", "ref_invalidfrom", "ref_component"))
                let current_value = current[key]
                    if previous_value != current_value
                        changed = true
                    end
                end
            end
        end
        if (changed)
            (ToStruct.tostruct(t, previous), ToStruct.tostruct(t, current))
        end
    end
end

"""
compareModelStateContract(previous::Dict{String,Any}, current::Dict{String,Any}, w::Workflow)
	compare viewmodel state for a contract section
"""
function compareModelStateContract(previous::Dict{String,Any}, current::Dict{String,Any}, w::Workflow)
    diff = []
    @show current["revision"]
    @show previous
    cr = compareRevisions(ContractRevision, previous["revision"], current["revision"])
    if (!isnothing(cr))
        push!(diff, cr)
    end
    @info "comparing Partner_refs"
    for i in 1:length(current["partner_refs"])
        @show current["partner_refs"]
        curr = current["partner_refs"][i]["rev"]
        @info "current pref rev"
        @show curr
        if isnothing(curr["id"]["value"])
            @info ("INSERT" * string(i))
            push!(diff, (nothing, ToStruct.tostruct(ContractPartnerRefRevision, curr)))
        else
            prev = previous["partner_refs"][i]["rev"]
            if curr["ref_invalidfrom"]["value"] == w.ref_version
                @info ("DELETE" * string(i))
                push!(diff, (ToStruct.tostruct(ContractPartnerRefRevision, prev), ToStruct.tostruct(ContractPartnerRefRevision, curr)))
                @info "DIFF="
                @show diff
            else
                @info ("UPDATE" * string(i))
                cprr = compareRevisions(ContractPartnerRefRevision, prev, curr)
                if (!isnothing(cprr))
                    push!(diff, cprr)
                end
            end
        end
    end
    @info "comparing product items"
    for i in 1:length(current["product_items"])
        @show current["product_items"]
        curr = current["product_items"][i]["revision"]
        @info "current pref rev"
        @show curr

    end
    @info "final DIFF"
    @show diff
    diff
end

"""
function load_role(role)::Vector{Dict{String,Any}}
    into ViewModel
"""

function load_role(role)::Vector{Dict{String,Any}}
    LifeInsuranceDataModel.connect()
    map(find(role)) do entry
        Dict{String,Any}("value" => entry.id.value, "label" => entry.value)
    end
end

"""
the list of persisted partners'ids
"""
function get_ids(partners::Vector{Partner})
    map(partners) do p
        Dict("value" => p.id.value, "label" => get_revision(Partner, PartnerRevision, p.ref_history, p.ref_version).description)
    end
end
end # module LifeInsuranceContracts
