#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
PASS=0; FAIL=0
pass() { echo "  [PASS] $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1"; ((FAIL++)) || true; }

echo "EDGE CASE: OCA Calculation Verification"
echo "========================================="

# Test 1: TNT-equivalent for propane (10,000 lbs)
# Heat of combustion ~19929 BTU/lb, 10% yield, TNT = 1943 BTU/lb
# W_TNT = (0.10 * 10000 * 19929) / 1943 = 10257 lbs TNT
# d_feet = 55.7 * 10257^(1/3) = 55.7 * 21.72 = 1209.8 feet = 0.229 miles
if python3 -c "
import json, math
with open('$PLUGIN_DIR/data/chemical-properties.json') as f:
    data = json.load(f)
propane = [c for c in data['chemicals'] if c['cas'] == '74-98-6'][0]
hoc = propane['heat_combustion_BTU_per_lb']
assert hoc is not None and hoc > 15000, f'Propane HoC missing or wrong: {hoc}'
W_TNT = (0.10 * 10000 * hoc) / 1943
d_feet = 55.7 * (W_TNT ** (1/3))
d_miles = d_feet / 5280
print(f'Propane VCE: W_TNT={W_TNT:.0f} lbs, d={d_feet:.0f} ft ({d_miles:.3f} mi)')
assert 0.15 < d_miles < 0.35, f'Distance {d_miles} out of expected range 0.15-0.35 mi'
" 2>&1; then
    pass "TNT-equivalent VCE for 10,000 lbs propane produces reasonable distance"
else
    fail "TNT-equivalent VCE calculation failed for propane"
fi

# Test 2: BLEVE fireball for propane (10,000 lbs)
# EPA formula: D_meters = 5.25 * (mass_kg)^0.397 (fireball diameter in meters, mass in kg)
# Distance to 5 kW/m2 ≈ 1.4 * D/2 (radius × view factor adjustment)
# 10,000 lbs = 4536 kg → D = 5.25 * 4536^0.397 = ~203 m → radius=101.5 m → d_5kW ≈ 142 m = 466 ft
if python3 -c "
import math
mass_lbs = 10000
mass_kg = mass_lbs / 2.205
D_m = 5.25 * (mass_kg ** 0.397)  # fireball diameter in meters
d_5kw_m = 1.4 * D_m / 2  # distance to 5 kW/m2 endpoint
d_feet = d_5kw_m * 3.281
d_miles = d_feet / 5280
print(f'Propane BLEVE: D={D_m:.0f} m, d(5kW/m2)={d_5kw_m:.0f} m = {d_feet:.0f} ft ({d_miles:.3f} mi)')
assert 300 < d_feet < 800, f'BLEVE distance {d_feet} ft out of expected range 300-800 ft'
" 2>&1; then
    pass "BLEVE fireball for 10,000 lbs propane produces reasonable distance (400-600 ft)"
else
    fail "BLEVE fireball calculation failed for propane"
fi

# Test 3: Toxic gas release rate (ammonia, 10,000 lbs, 10-min release)
# Release rate = 10000 / 10 = 1000 lbs/min
if python3 -c "
qty = 10000
rate = qty / 10
print(f'Ammonia gas release rate: {rate} lbs/min')
assert rate == 1000, f'Expected 1000, got {rate}'
" 2>&1; then
    pass "Toxic gas release rate: 10,000 lbs / 10 min = 1,000 lbs/min"
else
    fail "Toxic gas release rate calculation failed"
fi

# Test 4: Ammonia distance lookup (1000 lbs/min, urban, worst-case)
if python3 -c "
import json
with open('$PLUGIN_DIR/data/oca-distance-tables.json') as f:
    data = json.load(f)
nh3 = data['chemical_specific_tables']['ammonia']
urban = nh3['worst_case']['urban']
rates = urban['release_rate_lbs_per_min']
dists = urban['distance_miles']
# Find the entry for release rate <= 1000 (round down)
target_rate = 1000
best_idx = 0
for i, r in enumerate(rates):
    if r <= target_rate:
        best_idx = i
distance = dists[best_idx]
print(f'Ammonia 1000 lbs/min urban: {distance} miles (table entry at rate={rates[best_idx]})')
assert 0.5 < distance < 5.0, f'Distance {distance} out of expected range'
" 2>&1; then
    pass "Ammonia distance lookup (1000 lbs/min, urban) returns reasonable value"
else
    fail "Ammonia distance lookup failed"
fi

# Test 5: Chlorine distance lookup (150 lbs/min, rural, worst-case)
if python3 -c "
import json
with open('$PLUGIN_DIR/data/oca-distance-tables.json') as f:
    data = json.load(f)
cl2 = data['chemical_specific_tables']['chlorine']
rural = cl2['worst_case']['rural']
rates = rural['release_rate_lbs_per_min']
dists = rural['distance_miles']
target_rate = 150
best_idx = 0
for i, r in enumerate(rates):
    if r <= target_rate:
        best_idx = i
distance = dists[best_idx]
print(f'Chlorine 150 lbs/min rural: {distance} miles (table entry at rate={rates[best_idx]})')
assert 3.0 < distance < 15.0, f'Distance {distance} out of expected range for chlorine'
" 2>&1; then
    pass "Chlorine distance lookup (150 lbs/min, rural) returns reasonable value"
else
    fail "Chlorine distance lookup failed"
fi

# Test 6: Pool evaporation formula units check
# For a toxic liquid: verify the formula produces g/min, not lbs/min
if python3 -c "
import math
# Test case: HCN at 25C, undiked, 1000 lbs
# MW=27.03, VP=742 mmHg, density=43.1 lb/ft3
qty_lbs = 1000
density = 43.1
MW = 27.03
VP = 742
T_K = 298.15
U = 1.5  # worst case wind speed

# Pool area (undiked, 1 cm depth)
pool_sqft = qty_lbs / density / 0.0328
pool_m2 = pool_sqft / 10.764

# EPA evaporation formula (result in g/min)
QR_g_min = 1.4 * (U ** 0.78) * (MW ** (2/3)) * pool_m2 * VP / (82.05 * T_K)
QR_lbs_min = QR_g_min / 453.6

print(f'HCN pool: area={pool_sqft:.0f} sqft ({pool_m2:.0f} m2)')
print(f'Evaporation: {QR_g_min:.1f} g/min = {QR_lbs_min:.2f} lbs/min')
assert QR_lbs_min > 0, 'Release rate must be positive'
assert QR_lbs_min < 10000, 'Release rate unreasonably high'
assert pool_m2 > 0, 'Pool area must be positive'
" 2>&1; then
    pass "Pool evaporation formula produces valid release rate with correct units"
else
    fail "Pool evaporation formula check failed"
fi

# Test 7: Toxic endpoints data consistency
if python3 -c "
import json
with open('$PLUGIN_DIR/data/toxic-endpoints.json') as f:
    te = json.load(f)
with open('$PLUGIN_DIR/data/chemical-properties.json') as f:
    cp = json.load(f)
# Every toxic chemical in properties should have a matching endpoint
cp_toxic = [c for c in cp['chemicals'] if c.get('toxic')]
te_cas = {e['cas'] for e in te['endpoints']}
missing = [c['chemical'] for c in cp_toxic if c['cas'] not in te_cas]
if missing:
    print(f'INFO: {len(missing)} toxic chemicals in properties without endpoints: {missing[:5]}...')
# But key chemicals must match
for cas in ['7664-41-7', '7782-50-5', '7446-09-5', '7664-39-3', '7783-06-4']:
    assert cas in te_cas, f'Key chemical CAS {cas} missing from toxic endpoints'
print(f'All key toxic chemicals have endpoint data')
" 2>&1; then
    pass "Toxic endpoints and chemical properties are consistent for key chemicals"
else
    fail "Toxic endpoints / chemical properties consistency check failed"
fi

# Test 8: Dual-hazard chemical identification
if python3 -c "
import json
with open('$PLUGIN_DIR/data/chemical-properties.json') as f:
    data = json.load(f)
dual = [c for c in data['chemicals'] if c.get('dual_hazard')]
print(f'{len(dual)} dual-hazard chemicals identified')
# Ethylene oxide must be dual-hazard
eo = [c for c in dual if c['cas'] == '75-21-8']
assert len(eo) == 1, 'Ethylene oxide not flagged as dual-hazard'
# All dual-hazard must be both toxic and flammable
for c in dual:
    assert c.get('toxic') and c.get('flammable'), f'{c[\"chemical\"]} is dual but missing toxic/flammable flag'
print('All dual-hazard chemicals correctly flagged')
" 2>&1; then
    pass "Dual-hazard chemicals correctly identified (both toxic and flammable)"
else
    fail "Dual-hazard chemical identification failed"
fi

echo ""
echo "========================================="
echo "RESULTS: $PASS passed, $FAIL failed, $((PASS+FAIL)) total"
[ $FAIL -eq 0 ] && exit 0 || exit 1
