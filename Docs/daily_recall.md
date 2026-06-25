1. Wat doet feature_admission_v2?
feature_admission_v2 is de feature view waarin admission-records worden verrijkt met extra quality flags, zoals missing patient features, length-of-stay issues en cost issues. Deze view bepaalt ook met is_analysis_ready of een record geschikt is voor de gekozen technische analyse.

2. Wat doet feature_admission_analysis_ready?
feature_admission_analysis_ready is een gefilterde view op basis van feature_admission_v2. Alleen records met is_analysis_ready = TRUE worden meegenomen. Deze view is bedoeld als eerste technische analyse-subset.

3. Wat is het verschil tussen analysis-ready en fully clean?
Analysis-ready betekent dat een record voldoet aan de gekozen blocking rules voor een specifiek analysedoel. Fully clean betekent dat geen enkele vooraf gekozen quality flag aanwezig is. Fully clean is dus strenger en kan bij kleine of foutgevoelige datasets te weinig of geen records opleveren.

4. Waarom gebruiken we CASE?
CASE gebruiken we om conditionele logica toe te passen. We kunnen er tekstlabels mee maken, boolean flags mee bouwen, of TRUE/FALSE omzetten naar 1/0 zodat we met SUM() kunnen tellen.

5. Waarom gebruiken we CTE?
Een CTE is een tijdelijk benoemd resultaat binnen één query. We gebruiken het om eerst een tussenresultaat te berekenen en daarna op dat resultaat verder te queryen. Het wordt niet permanent opgeslagen zoals een echte tabel of view.

6. Wat is het verschil tussen WHERE en HAVING?
WHERE filtert rijen vóórdat er gegroepeerd wordt. HAVING filtert groepen nadat GROUP BY en aggregaties zoals COUNT(), SUM() of AVG() zijn uitgevoerd.

7. Waarom telt COUNT(is_analysis_ready) niet alleen TRUE?
count telt alle niet null waarden in een kolom, dus daar valt alles onder behalve null