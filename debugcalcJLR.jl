using BitemporalPostgres, LifeInsuranceDataModel, LifeInsuranceProduct
using JSON, SearchLight, SearchLightPostgreSQL, TimeZones
ENV["SEARCHLIGHT_USERNAME"] = "postgres"
ENV["SEARCHLIGHT_PASSWORD"] = "postgres"
SearchLight.Configuration.load() |> SearchLight.connect
cid = 2
h = find(Contract, SQLWhereExpression("id =?", cid))[1].ref_history
vi = find(ValidityInterval, SQLWhereExpression("ref_history=?", h), order=["ValidityInterval.id"])[1];
txntime = vi.tsdb_validfrom
reftime = vi.tsworld_validfrom

cs = csection(cid, txntime, reftime)

ti = cs.product_items[1].tariff_items[1]

tariffparms = JSON.parse(ti.tariff_ref.ref.revision.parameters)
println(tariffparms)
interface_id = ti.tariff_ref.ref.revision.interface_id
tif = get_tariff_interface(Val(interface_id))
tgt = tif.calls["calculation_target"]
tgt["selected"] = "net premium"
parms = tgt[tgt["selected"]]
parms["n"]["value"] = "20"
parms["frequency"]["value"] = "2"
parms["begin"]["value"] = "2023-04-01"
parms["sum insured"]["value"] = "20000"

tif.calculator(interface_id, ti, tif.calls)

println(tif.calls)