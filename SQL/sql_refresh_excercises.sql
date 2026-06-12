# Toon alle patienten
select *
from patients p;

Toon alleen patient_id, birth_date en gender
select patient_id, birth_date, gender 
from patients p;

# Tel het aantal patienten
select count(*)
from patients p;

# Tel het aantal patiënten per gender
select count(gender), gender
from patients p 
group by p.gender;

# Zoek patiënten zonder postcode
select patient_id, first_name, last_name
from patients p 
where p.postcode is null or p.postcode = '';

# Zoek patiënten met geboortedatum in de toekomst
select patient_id, first_name, last_name
from patients p
where p.birth_date > '2026-06-12';

# Zoek dubbele patient_id’s
select count(patient_id), patient_id
from patients p 
group by p.patient_id 
having count(p.patient_id ) > 1;