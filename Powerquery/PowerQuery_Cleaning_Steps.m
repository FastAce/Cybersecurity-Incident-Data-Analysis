let
    RawPath = "data/raw_cyber_incidents.csv",

    Source = Csv.Document(File.Contents(RawPath),[Delimiter=",", Columns=20, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),

    TextTrimmed = Table.TransformColumns(PromotedHeaders, List.Transform(
        {"Region","Department_Affected","Asset_Type","Incident_Type","Severity","Priority","Detection_Source","Status","Business_Impact","Root_Cause","Data_Sensitivity","SLA_Breached","Analyst"},
        each {_, Text.Trim, type text}
    )),

    IncidentFixed = Table.ReplaceValue(TextTrimmed,
        each [Incident_Type],
        each
            let t = Text.Trim([Incident_Type]) in
            if List.Contains({"Phishing","Phising","Phshing"}, t) then "Phishing" else
            if List.Contains({"Malware","Maleware","Mal-ware"}, t) then "Malware" else
            if List.Contains({"Ransomware","Ransomeware","Ransom-ware"}, t) then "Ransomware" else
            if List.Contains({"Unauthorized Access","Unauthorised Access","Unauthorized  Access"}, t) then "Unauthorized Access" else
            if List.Contains({"Data Exfiltration","Data Exfiltraton","Data-Exfiltration"}, t) then "Data Exfiltration" else
            if List.Contains({"DDoS","DDOS","Ddos"}, t) then "DDoS" else
            if List.Contains({"Misconfiguration","Misconfig","Missconfiguration"}, t) then "Misconfiguration" else
            if List.Contains({"Lost/Stolen Device","Lost Device","Stolen Device"}, t) then "Lost/Stolen Device" else t,
        Replacer.ReplaceValue, {"Incident_Type"}),

    PriorityFixed = Table.ReplaceValue(IncidentFixed,
        each [Priority],
        each
            let p = Text.Lower(Text.Trim([Priority])) in
            if Text.Contains(p, "p1") or Text.Contains(p, "critical") then "P1 - Critical" else
            if Text.Contains(p, "p2") or Text.Contains(p, "high") then "P2 - High" else
            if Text.Contains(p, "p3") or Text.Contains(p, "medium") then "P3 - Medium" else
            if Text.Contains(p, "p4") or Text.Contains(p, "low") then "P4 - Low" else [Priority],
        Replacer.ReplaceValue, {"Priority"}),

    CostDigits = Table.TransformColumns(PriorityFixed, {{"Estimated_Cost_EUR",
        each try Number.From(Text.Select(_, {"0".."9"})) otherwise null, type number}}),

    DurationTextClean = Table.TransformColumns(CostDigits, List.Transform(
        {"Time_to_Detect_min","Time_to_Contain_min","Time_to_Resolve_min","Downtime_min"},
        each {_, each Text.Replace(Text.Trim(Text.From(_)), " min",""), type text}
    )),
    DurationToNumber = Table.TransformColumns(DurationTextClean, List.Transform(
        {"Time_to_Detect_min","Time_to_Contain_min","Time_to_Resolve_min","Downtime_min"},
        each {_, each try Number.From(_) otherwise null, type number}
    )),
    DurationNoNegative = Table.TransformColumns(DurationToNumber, List.Transform(
        {"Time_to_Detect_min","Time_to_Contain_min","Time_to_Resolve_min","Downtime_min"},
        each {_, each if _ <> null and _ < 0 then null else _, type number}
    )),

    DateParsed1 = Table.TransformColumns(DurationNoNegative, {{"Date_Incident", each try DateTime.FromText(_) otherwise null, type datetime}}),
    DateParsed2 = Table.TransformColumns(DateParsed1, {{"Date_Incident", each if _ = null then try DateTime.FromText(_, [Format=\"fr-FR\"]) otherwise _ else _, type datetime}}),

    FillNA = Table.ReplaceValue(DateParsed2,null,"Unknown",Replacer.ReplaceValue,{"Detection_Source","Root_Cause","Data_Sensitivity","SLA_Breached"}),

    Typed = Table.TransformColumnTypes(FillNA,{
        {"Incident_ID", type text},
        {"Region", type text},
        {"Department_Affected", type text},
        {"Asset_Type", type text},
        {"Incident_Type", type text},
        {"Severity", type text},
        {"Priority", type text},
        {"Detection_Source", type text},
        {"Status", type text},
        {"Time_to_Detect_min", Int64.Type},
        {"Time_to_Contain_min", Int64.Type},
        {"Time_to_Resolve_min", Int64.Type},
        {"Business_Impact", type text},
        {"Downtime_min", Int64.Type},
        {"Estimated_Cost_EUR", Int64.Type},
        {"Root_Cause", type text},
        {"Data_Sensitivity", type text},
        {"SLA_Breached", type text},
        {"Analyst", type text},
        {"Date_Incident", type datetime}
    }),

    Sorted = Table.Sort(Typed,{{"Incident_ID", Order.Ascending},{"Date_Incident", Order.Descending}}),
    Deduped = Table.Distinct(Sorted, {"Incident_ID"}),

    YearAdded = Table.AddColumn(Deduped, "Year", each Date.Year([Date_Incident]), Int64.Type),
    MonthAdded = Table.AddColumn(YearAdded, "Month", each Date.MonthName([Date_Incident]), type text),
    ResolveHours = Table.AddColumn(MonthAdded, "Resolve_Hours", each Number.Round([Time_to_Resolve_min] / 60, 2), type number),
    IsCritical = Table.AddColumn(ResolveHours, "Is_Critical", each if [Severity] = "Critical" then 1 else 0, Int64.Type),

    PriorityFromSev = Table.TransformColumns(IsCritical, {{"Priority", each
        if [Severity] = "Critical" then "P1 - Critical"
        else if [Severity] = "High" then "P2 - High"
        else if [Severity] = "Medium" then "P3 - Medium"
        else "P4 - Low"}, type text}),

    Result = PriorityFromSev
in
    Result
