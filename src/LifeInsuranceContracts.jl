module LifeInsuranceContracts
using LifeInsuranceDataModel
using LifeInsuranceProduct
using BitemporalPostgres
using SearchLight
greet() = print("Hello World!")

LifeInsuranceProduct.get_tariff_interface(Val(0))
end # module LifeInsuranceContracts
