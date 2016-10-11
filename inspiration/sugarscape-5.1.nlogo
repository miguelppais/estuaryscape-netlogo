breed [agents agent]
breed [diseases disease]
undirected-link-breed [trades trade]
directed-link-breed [loans loan]
agents-own [
    vision sugar spice initSugar initSpice sugarMetabolism sugarMetabolismGenotype spiceMetabolism spiceMetabolismGenotype 
    sugarGathered spiceGathered age maxage cultureTags immuneTags immuneGenotype neighborhood
    sex parentStep fertileStart fertileEnd welfare MRS status tickIncome infections children foresight]
diseases-own [diseaseTags fever]
patches-own [psugar pspice maxpsugar maxpspice pollution]
trades-own [sugarAmount spiceAmount price]
loans-own [debtAge debtAmount]
globals [visionRange metabolismRange sugarRange foresightRange ageRange sexRange fertileRanges
    includeMyPatch? scapeColor useR? useS? agentLayout numCultureTags numImmuneTags numDiseaseTags
    male female tradePriceProduct showLinks? showscape?]

to setup-globals
  set showLinks? false
  set showScape? true
  set metabolismRange list minMetabolism maxMetabolism
  set visionRange list minVision maxVision
  set foresightRange list 0 maxForesight
  ifelse replacementRule = "R" [set useR? true set useS? false]
    [
    ifelse replacementRule = "S" [set useR? false set useS? true]
      [
      set useR? false set useS? false
      ]
    ]
  set sugarRange list minInitialSugar maxInitialSugar
  ifelse distribution = "corner" [set agentLayout 1] [set agentLayout 0] ; 0 = whole scape, 1 = lower left, 2 = lower left and top right
  set ageRange  [60 100]
  set fertileRanges   [ [[12 15][50 60]] [[12 15][40 50]] ]
  set numCultureTags  11
  set numImmuneTags   50
  set numDiseaseTags  10
  set includeMyPatch? true      ; Whether to include me in the search neighborhood.
  set scapeColor      orange    ; Orange or other dark color makes scape clearer. Yellow is usual.
  set male            0         ; Constant for "male"
  set female          1         ; Constant for "female"
end

to preset0
end

to preset1
  set-rules 400 "scatter" 1 0 1 1 1 4 1 6 5 25 0 "none" false false 10 false 0 false 0 false false false false 0 false 0 0
  set agentColors "red"
  set showScape "sugar and spice"
end

to preset2
  set-rules 400 "corner" 1 0 2 1 0 4 1 10 5 25 0 "none" false false 10 false 0 false 0 false false false false 0 false 0 0
  set agentColors "red"
  set showScape "sugar and spice"
end

to preset3
  set-rules 400 "scatter" 1 0 1 1 1 4 1 6 50 100 0 "S" false false 10 false 0 false 0 false false false false 0 false 0 0
  set agentColors "fertility"
  set showScape "sugar and spice"
end

to preset4
  set-rules 400 "scatter" 1 1 1 1 1 4 1 6 5 25 0 "none" false false 10 false 0 false 0 false true false false 0 false 0 0
  set agentColors "sugar/spice"
  set showScape "sugar and spice"
end

to preset5
  set-rules 400 "scatter" 1 1 1 1 1 4 1 6 5 25 0 "none" false false 10 false 0 false 0 false true true false 0 false 0 0
  set agentColors "sugar/spice"
  set showScape "sugar and spice"
end

to preset6
  set-rules 400 "scatter" 1 0 1 1 1 4 1 6 50 100 0 "S" false false 10 false 0 false 0 false false false true 0.1 false 0 0
  set agentColors "lender/borrower"
  set showScape "sugar and spice"
end

to preset7
  set-rules 600 "scatter" 1 0 1 1 1 4 1 6 10 50 0 "none" false false 10 false 0 false 0 false false false false 0 true 10 1
  set agentColors "infected"
  set showScape "sugar and spice"
end

to preset8
  set-rules 500 "scatter" 1 1 1 1 1 4 1 6 25 50 0 "S" false false 10 false 0 false 0 false true true false 0 false 0 0
  set agentColors "sugar/spice"
  set showScape "sugar and spice"
end

to set-rules [num dist suggbr spigbr suggbi spigbi met1 met2 vis1 vis2 sug1 sug2 for rrule I? seasons? speriod P? pr D? dr K? Sp? T? L? inter E? numDis sevDis] ; Utility used by the presets
  set numAgents         num
  set distribution      dist
  set sugarGrowBackRate suggbr
  set spiceGrowBackRate spigbr
  set sugarGrowBackInterval  suggbi
  set spiceGrowBackInterval  spigbi
  set minMetabolism     met1
  set maxMetabolism     met2
  set minVision         vis1
  set maxVision         vis2
  set minInitialSugar   sug1
  set maxInitialSugar   sug2
  set maxForesight      for
  set replacementRule   rrule
  set useI?             I?
  set useSeasons?       seasons?
  set seasonPeriod      speriod
  set useP?             P?
  set pollutionRate     pr
  set useD?             D?
  set diffusionrate     dr
  set useK?             K?
  set spice?            Sp?
  set useT?             T?
  set useL?             L?
  set interest          inter
  set useE?             E?
  set numDiseases       numDis
  set diseaseSeverity   sevDis
end

to set-color ; Utility to change the color of the agents accoriding to rules and settings
  set color red
  if useE? and agentColors = "infected"
    [
    ifelse length infections > 0 [set color lime] [set color blue]
    ]
  if useL? and agentColors = "lender/borrower"
    [
    ifelse status = 1 [set color magenta]
      [
      ifelse status = 2 [set color violet]
        [
        ifelse status = 3 [set color pink] [set color gray]
        ]
      ]
    ]
  if useS? and agentColors = "fertility"
    [
    ifelse age > fertileend [set color grey]
      [
      ifelse ticks > 0 and ticks = parentStep [set color yellow]
        [
        ifelse ticks > 1 and age = 0 [set color cyan]
          [
          ifelse (sex = male) [set color red] [set color blue]
          ]
        ]
      ]
    ]
  if useK? and agentColors = "culture"
    [
    ifelse (sum cultureTags > length cultureTags / 2) [set color red] [set color blue]
    ]
  if agentColors = "sugar/spice"
    [
    ifelse spiceGathered = 0 and sugarGathered = 0 [set color 0]
      [
      ifelse spiceGathered = 0 or sqrt(sugarGathered / spiceGathered) > 2 [set color 15]
        [
        ifelse sugarGathered = 0 or sqrt(sugarGathered / spiceGathered) < 0.5 [set color 105]
          [
          ifelse sqrt(sugarGathered / spiceGathered) > 1 [set color 10 + 5 * (sqrt(sugarGathered / spiceGathered) - 1)]
          [set color 100 - 5 * (sqrt(sugarGathered / spiceGathered) - 1)/(0.5)]
          ]
        ]
      ]
    ]
end

to setup [preset?] ; Sets up patches, agents and diseases
   ca
  if preset? [run word "preset" substring Presets 0 position ":" Presets]
  if useT? and not spice? [show "rule-T requires spice" beep stop] ; Check for incompatable rule-sets
  if useL? and spice? [show "rule-L does not support spice" beep stop]
  if useL? and replacementRule != "S" [show "rule-L facilitates agents in carrying out rule-S" beep stop]
  if useI? and replacementRule != "S" [show "rule-I requires rule-S" beep stop]
  setup-globals
  set-default-shape agents "circle"
  create-agents numAgents
  if useE? [create-diseases numDiseases [set hidden? true setup-diseases]]
  my-setup-plots
  setup-patches
  ask agents
    [
    setup-agents
    set-color
    ]
    reset-ticks
end

to go
  tick
  if useT? [ask trades [die]]
  if useL? [ask loans [set debtAge debtAge + 1]] ; Add to the time of loans
  ask agents 
    [
    rule-M
    if useT? [rule-T]
    if useL? [rule-L]
    if useS? [rule-S]
    if useK? [rule-K]
    if useE? [rule-E]
    ]
  ask patches
    [
    rule-G sugarGrowBackRate spiceGrowBackRate
    ]
  ask agents ; Color must also be set after all interractions have finished
    [
    set-color
    ]
  if useD? [diffuse pollution diffusionRate] ; Diffuse pollution
  if count agents = 0 [stop]
  do-plots
end

to do-plots ; Plotting procedure called each step
  set-current-plot "Agents"
  set-current-plot-pen "Agents"
  plot count agents
  if useE?
    [
    set-current-plot-pen "Infected"
    plot count agents with [any? turtle-set infections]
    ]
  set-current-plot "Line"
  ifelse useT?
    [
    set-current-plot-pen "Trade Volume"
    plot sum[sugarAmount + spiceAmount] of trades
    ]
    [
    ifelse useL?
      [
      set-current-plot-pen "Lenders"
      plot count agents with [status = 1]
      set-current-plot-pen "Lender/Borrowers"
      plot count agents with [status = 2]
      set-current-plot-pen "Borrowers"
      plot count agents with [status = 3]
      set-current-plot-pen "Black"
      plot count agents with [status = 0]
      ]
      [
      ifelse maxForesight != 0
        [
        set-current-plot-pen "Foresight"
        plot mean [foresight] of agents
        ]
        [
        set-current-plot-pen "Vision"
        plot mean [vision] of agents
        set-current-plot-pen "Sugar Metabolism"
        plot mean [sugarMetabolismGenotype] of agents
        if spice?
          [
          set-current-plot-pen "Spice Metabolism"
          plot mean [spiceMetabolismGenotype] of agents
          ]
        ]
      ]
    ]
  set-current-plot "Scatter"
  if useT?
    [
    set-current-plot-pen "Price"
    if count trades > 0
      [
      let m 1
      ask trades [set m m * price]
      set m m ^ (1 / count trades)
      plot m
      ]
    set-current-plot-pen "1"
    plot 1
    ]
  if (ticks = 1 or ticks mod 10 = 0) 
    [
    set-current-plot "Histogram"
    clear-plot
    ifelse useK? 
      [
      let l []
      let ll []
      let i 0
      repeat numCultureTags 
        [
        set ll remove 0 ([item i cultureTags] of agents)
        set l sentence l map [? * i] ll
        set i i + 1
        ]
      set-current-plot-pen "Tags"
      set-plot-x-range 0 numCultureTags
      set-plot-y-range 0 count agents
      set-histogram-num-bars numCultureTags
      histogram l
      ] 
      [
      ifelse useS? 
        [
        set-current-plot-pen "Ages"
        set-plot-x-range 0 max ageRange
        set-histogram-num-bars 10
        histogram [age] of agents
        ] 
        [
        set-current-plot-pen "Wealth"
        set-plot-x-range 0 (int ((max [sugar + spice] of agents + 9) / 10) * 10)
        set-histogram-num-bars 10
        histogram [sugar + spice] of agents
        ]
      ]
    ]
end

to rule-M ; Motion rule
  let p 0
  let v 0
  let d 0
  let sr sugar
  let srm sugarMetabolism
  let sp spice
  let spm spiceMetabolism
  let for foresight
  let ps (patches at-points neighborhood) with [count agents-here = 0]
  ifelse (count ps > 0) 
    [
    ifelse spice?
      [
      set v [find-welfare (sr + psugar / pollution) srm (sp + pspice / pollution) spm for] of max-one-of ps [find-welfare (sr + psugar / pollution) srm (sp + pspice / pollution) spm for] ; v is max welfare gain w/in vision
      set ps ps with [find-welfare (sr + psugar / pollution) srm (sp + pspice / pollution) spm for = v] ; ps is legal sites w/ v sugar
      set d distance min-one-of ps [distance myself]  ; d is min dist from me to ps agents
      set p one-of ps with [distance myself = d] ; p is one of the min dist patches
      if (find-welfare (sr + psugar / pollution) srm (sp + pspice / pollution) spm for >= v and includeMyPatch?) [set p patch-here]
      ]
      [
      set v [psugar / pollution] of max-one-of ps [psugar / pollution]  ; v is max sugar w/in vision
      set ps ps with [psugar / pollution = v]  ; ps is legal sites w/ v sugar
      set d distance min-one-of ps [distance myself] ; d is min dist from me to ps agents
      set p one-of ps with [distance myself = d] ; p is one of the min dist patches
      if (psugar / pollution >= v and includeMyPatch?) [set p patch-here]
      ]
    setxy [pxcor] of p [pycor] of p ; jump to p
    ]
    [
    set p patch-here ; If no empty sites can be seen, stay still
    ]
  set sugar sugar + [psugar] of p ; Consume it's sugar
  set tickIncome [psugar] of p - sugarMetabolism
  set sugarGathered sugarGathered + [psugar] of p
  set sugar sugar - sugarMetabolism ; Metabolise sugar
  if useP?
    [
    ask p[set pollution [pollution] of p + ( [psugar] of p + sugarMetabolism ) * pollutionRate]  
;    set [pollution] of p [pollution] of p + ( [psugar] of p + sugarMetabolism ) * pollutionRate ; Add to pollution of the patch
    
    ]
  set-psugar 0
  if spice?
    [
    set spice spice + [pspice] of p ; Consume it's spice
    set spiceGathered spiceGathered + [pspice] of p
    set spice spice - spiceMetabolism ; Metabolise spice
    set-pspice 0
    ]
  set age age + 1
  if (sugar <= 0 or (spice? and spice <= 0) or age > maxage) [if useR? [rule-R] if useI? [rule-I] die]
  if spice? [set-welfareMRS] ; Calculate new welfare and MRS
end

to rule-T
  let p 0
  let a self
  let as []
  let tSugar 0
  let tSpice 0
  let tsSugar 0
  let tsSpice 0
  let tWelfare 0
  let tsWelfare 0
  let x 0
  let y 0
  let traded? true
  ask neighbors4
    [
    ask agents-here [set as fput self as]
    ]
  if empty? as [stop]
  while [traded?]
    [
    set traded? false
    set as sort-by [random 2 = 0] as
    foreach as
      [
      if [MRS] of ? != [MRS] of a ; Check only agents with unequal MRS
        [
        set x ([MRS] of a < [MRS] of ?) ; Record which MRS is initially higher
        set p sqrt([MRS] of a * [MRS] of ?) ; Set a price
        ifelse p >= 1
          [
          ifelse [MRS] of a < [MRS] of ?
            [
            set tSugar [sugar] of a - 1 set tSpice [spice] of a + p
            set tsSugar [sugar] of ? + 1 set tsSpice [spice] of ? - p
            ]
            [
            set tSugar [sugar] of a + 1 set tSpice [spice] of a - p
            set tsSugar [sugar] of ? - 1 set tsSpice [spice] of ? + p
            ]
          ]
          [
          ifelse [MRS] of a < [MRS] of ?
            [
            set tSugar [sugar] of a - (1 / p) set tSpice [spice] of a + 1
            set tsSugar [sugar] of ? + (1 / p) set tsSpice [spice] of ? - 1
            ]
            [
            set tSugar [sugar] of a + (1 / p) set tSpice [spice] of a - 1
            set tsSugar [sugar] of ? - (1 / p) set tsSpice [spice] of ? + 1
            ]
          ]
        if tSugar > 0 and tSpice > 0 and tsSugar > 0 and tsSpice > 0
          [
          set y (find-MRS tSugar [sugarMetabolism] of a tSpice [spiceMetabolism] of a [foresight] of a) < (find-MRS tsSugar [sugarMetabolism] of ? tsSpice [spiceMetabolism] of ? [foresight] of ?) ; Record which MRS is now higher
          set tWelfare find-welfare tSugar [sugarMetabolism] of a tSpice [spiceMetabolism] of a [foresight] of a
          set tsWelfare find-welfare tsSugar [sugarMetabolism] of ? tsSpice [spiceMetabolism] of ? [foresight] of ?
          if x = y and tWelfare > [welfare] of a and tsWelfare > [welfare] of ? ; If the trade does not corss the MRS over and benefits the welfare of both...
            [
            ask a [set sugar tSugar]
            ;;set [sugar] of a tSugar
            ask a [set spice tSpice]
            ;;set [spice] of a tSpice
            ask ? [set sugar tsSugar]
            ;;set [sugar] of ? tsSugar
            ask ? [set spice tsSpice]
            ;;set [spice] of ? tsSpice
            ask a [set-welfareMRS]
            ask ? [set-welfareMRS]
            create-trade-with ?
              [
              set price p ifelse p >= 1
                [
                set sugarAmount 1
                set spiceAmount p
                ]
                [
                set sugarAmount 1 / p
                set spiceAmount 1
                ]
              ifelse showLinks? [set hidden? false] [set hidden? true] set color black
              ]
            set traded? true ; Loop continutes until no viable trades can be made
            ]
          ]
        ]
      ]
    ]
end

to rule-L ; Lending and borrowing rule
  let amount2borrow 0
  let as []
  let debtLinks []
  let lender 0
  let debt 0
  ask my-in-loans with [debtAge = 10] [set debtLinks fput self debtLinks]
  set debtLinks sort-by [random 2 = 0] debtLinks
  foreach debtLinks
    [
    set lender [other-end] of ?
    set debt [debtAmount] of ?
    ask ? [die]
    ifelse sugar > debt
      [
      set sugar sugar - debt
      ask lender [set sugar [sugar] of lender + debt]
      ;;set [sugar] of lender [sugar] of lender + debt
      set tickIncome tickIncome - debt
      ]
      [
      set sugar sugar / 2
      ask lender [set sugar [sugar] of lender + sugar / 2]
      ;;set [sugar] of lender [sugar] of lender + sugar / 2
      ask ? [die]
      create-loan-from lender [set debtAge 0 set debtAmount (1 + interest) * (debt - [sugar] of myself / 2) ifelse showLinks? [set hidden? false][set hidden? true] set color red]
      ]
    ]
  ifelse borrower? 
    [
    ask neighbors4 
      [
      ask agents-here with [lender?] [set as fput self as]
      ]
    set as sort-by [random 2 = 0] as
    foreach as 
      [
      ifelse [age] of ? < [fertileEnd] of ? ; There are 2 types of lender. Those too old to be fertile, and those with an excess
        [
        set amount2borrow min list (initSugar - sugar) [sugar - initSugar] of ? ; Maximum lend is the excess, maximum borrow is the amount needed to reproduce
        ]
        [
        set amount2borrow min list (initSugar - sugar) [sugar / 2] of ? ; Maximum lend is half the total wealth, maximum borrow is the amount needed to reproduce
        ]
      set sugar sugar + amount2borrow
      ask ? [set sugar [sugar] of ? - amount2borrow]
      ;;set [sugar] of ? [sugar] of ? - amount2borrow
      create-loan-from ? [set debtAge 0 set debtAmount amount2borrow * (1 + interest) ifelse showLinks? [set hidden? false][set hidden? true] set color black]
      if not borrower? [stop]
      ]
    ]
    [
    if lender?
      [
      ask neighbors4 
        [
        ask agents-here with [borrower?] [set as fput self as]
        ]
      set as sort-by [random 2 = 0] as
      foreach as 
        [
        ifelse age < fertileEnd
        [
        set amount2borrow min list (sugar - initSugar) [initSugar - sugar] of ?
        ]
        [
        set amount2borrow min list (sugar / 2) ([initSugar - sugar] of ?)
        ]
        set sugar sugar - amount2borrow
        ask ? [set sugar [sugar] of ? + amount2borrow]
        ;;set [sugar] of ? [sugar] of ? + amount2borrow
        create-loan-to ? [set debtAge 0 set debtAmount amount2borrow * (1 + interest) ifelse showLinks? [set hidden? false][set hidden? true] set color black]
        if not lender? [stop]
        ]
      ]
    ]
  ifelse count my-out-loans > 0 and count my-in-loans = 0 [set status 1]
    [
    ifelse count my-out-loans > 0 and count my-in-loans > 0 [set status 2]
      [
      ifelse count my-out-loans = 0 and count my-in-loans > 0 [set status 3]
        [set status 0]
      ]
    ]
end

to rule-I
  if not any? turtle-set children [stop]
  let as []
  let ls []
  ask turtle-set children [set as lput self as]
  if useL? [ask my-out-loans [set ls lput self ls] ]
  let numChildren length as
  let sugarInherit sugar / numChildren
  let spiceInherit sugar / numChildren
  foreach as
    [
     ask ? [set sugar [sugar] of ? + sugarInherit] 
    ;;set [sugar] of ? [sugar] of ? + sugarInherit
    ask ? [set spice [spice] of ? + spiceInherit]
    ;;set [spice] of ? [spice] of ? + spiceInherit
    foreach ls
      [
      create-loan-to [end2] of ? [set debtAge [debtAge] of ? set debtAmount [debtAmount] of ? / numChildren]
      ]
    ]
end

to rule-E ; Disease response and transmissions rule
  let a 0
  let as 0
  let tss 0
  let l 0
  let n 0 
  let done? 0
  let startPos 0
  let immuneTarget 0
  let listInfections 0
  let possibleTransmit []
  set a self
  set as []
  set listInfections []
  if not any? turtle-set infections [stop]
  ask neighbors4
    [
    ask agents-here [set as fput self as]
    ]
  foreach as
    [
    set tss ?
    set possibleTransmit []
    foreach infections [if not member? ? [infections] of tss [set possibleTransmit lput ? possibleTransmit] ]
    if any? turtle-set possibleTransmit [
      ask ? [set infections lput item (random length possibleTransmit) possibleTransmit [infections] of ?]
      ;;set [infections] of ? lput item (random length possibleTransmit) possibleTransmit [infections] of ?
      ]
    ]
  set immuneTarget item (random length infections) infections
  set startPos find-minhamdist immuneTarget
  set l length [diseaseTags] of immuneTarget
  ifelse immune? immuneTarget [set done? true] [set done? false]
  set n 0
  while [not done?]
    [
    if item n ([diseaseTags] of immuneTarget) != item (n + startPos) immuneTags
      [
      set immuneTags replace-item (n + startPos) immuneTags (item n [diseaseTags] of immuneTarget)
      set done? true
      ]
    set n n + 1
    ]
  foreach infections
    [
    if immune? ? [set infections remove ? infections]
    ]
  ifelse not empty? infections
    [
    set sugarMetabolism sugarMetabolismGenotype + max [fever] of turtle-set infections
    set spiceMetabolism spiceMetabolismGenotype + max [fever] of turtle-set infections
    ]
    [
    set sugarMetabolism sugarMetabolismGenotype
    set spiceMetabolism spiceMetabolismGenotype
    ]
end

to rule-R    ; Replacement rule
  ask patch-here [sprout-agents 1 [setup-agents]]
end

to rule-S    ; Sexual reproduction rule
  let as 0
  let a 0
  let ps 0
  let p 0
  if (fertile?) 
    [
    set a self
    set as []
    ask neighbors4 
      [
      ask agents-here with [sex != [sex] of a and fertile?] [set as fput self as]
      ]
    set as sort-by [random 2 = 0] as
    foreach as 
      [
      ask ? [set ps [self] of (neighbors4 with [count agents-here = 0])]
      set ps sentence ps [self] of (neighbors4 with [count agents-here = 0])
      if length ps != length remove-duplicates ps [show "dups!"]
      if (not empty? ps) 
        [
        set p item (random length ps) ps
        ask p
          [
          sprout-agents 1
            [
            ask ? [set sugar [sugar] of ? - ([initSugar] of ? / 2)] 
            ;;set [sugar] of ? [sugar] of ? - ([initSugar] of ? / 2)
            ask a [set sugar [sugar] of a - ([initSugar] of a / 2)]
            ;;set [sugar] of a [sugar] of a - ([initSugar] of a / 2)
            if spice?
              [
              ask ? [set spice [spice] of ? - ([initSpice] of ? / 2)] 
              ;;set [spice] of ? [spice] of ? - ([initSpice] of ? / 2)
              ask a [set spice [spice] of a - ([initSpice] of a / 2)]
              ;;set [spice] of a [spice] of a - ([initSpice] of a / 2)
              ]
            ask ? [set parentStep ticks]  
            ;;set [parentStep] of ? ticks
            ask a [set parentStep ticks]
            ;;set [parentStep] of a ticks
            ask a [set children lput self [children] of a]
            ;;set [children] of a lput self [children] of a
            ask ? [set children lput self [children] of ?]
            ;;set [children] of ? lput self [children] of ?
            let inheritCulture []
            let n 0
            repeat numCultureTags
              [
              ifelse random 2 = 0 [set inheritCulture lput item n [cultureTags] of a inheritCulture][set inheritCulture lput item n [cultureTags] of ? inheritCulture]
              set n n + 1
              ]
            let inheritImmune []
            let inheritInfections []
            set n 0
            repeat numImmuneTags
              [
              ifelse random 2 = 0 [set inheritImmune lput item n [immuneGenotype] of a inheritImmune][set inheritImmune lput item n [immuneGenotype] of ? inheritImmune]
              set n n + 1
              ]
            if useE?
              [
              set inheritInfections sentence [infections] of a [infections] of ?
              set inheritInfections remove-duplicates inheritInfections
              ]
            setup-agent (([initSugar / 2] of ?) + ([initSugar / 2] of a))
            (([initSpice / 2] of ?) + ([initSpice / 2] of a))
            (item random 2 list [sugarMetabolismGenotype] of ? [sugarMetabolismGenotype] of a)
            (item random 2 list [spiceMetabolismGenotype] of ? [spiceMetabolismGenotype] of a)
            (item random 2 list [vision] of ? [vision] of a)
            (item random 2 list [foresight] of ? [foresight] of a)
            list pxcor pycor inheritImmune inheritInfections inheritCulture
            ]
          ]
        ]
      if (not fertile?) [stop]
      ]
    ]
end

to rule-K   ; Culture rule
  let i 0
  let myTags cultureTags
  ask neighbors4 
    [
    ask agents-here 
      [
      set i random length cultureTags
      set cultureTags replace-item i cultureTags (item i myTags)
      ]
    ]
end

to rule-G [n m] ; Growback rule
  let sugInterval sugarGrowBackInterval
  let spiInterval spiceGrowBackInterval
  if useSeasons?
    [
      ifelse (ticks mod (2 * seasonPeriod)) / seasonPeriod < 1
      [
      if pycor <= 0
        [
        set sugInterval sugInterval * 4
        set spiInterval spiInterval * 4
        ]
      ]
      [
      if pycor >= 0
        [
        set sugInterval sugInterval * 4
        set spiInterval spiInterval * 4
        ]
      ]
    ]
  if ticks mod sugInterval = 0 [set-psugar psugar + n]
  if spice? and ticks mod spiInterval = 0 [set-pspice pspice + m]
end

to-report fertile? ; Utility to report whether or not I'm fertile
  ifelse spice? [report age >= fertileStart and age <= fertileEnd and sugar >= initSugar and spice >= initSpice]
  [report age >= fertileStart and age <= fertileEnd and sugar >= initSugar]
end

to-report borrower? ; Utility to identify if I'm in need of borrowing
  report (age >= fertileStart and age <= fertileEnd and sugar < initSugar and tickIncome > 0 and (count my-in-loans with [color = red]) = 0)
end

to-report lender? ; Utility to identify if I can justify lending
  report (age > fertileEnd or (sugar - sum [debtAmount] of my-in-loans) > initSugar)
end

to-report immune? [dis] ; Utility to identify I am immune to a disease
  let strain word [diseaseTags] of dis "x"
  let immune word immuneTags "x"
  ifelse member? substring strain 1 ( (length strain) - 2 ) substring immune 1 ( (length immune) - 2 ) [report true] [report false]
end

to setup-agents
  let ds []
  if useE?
    [
    ask n-of 4 diseases [set ds lput self ds]
    ]
  setup-agent get-param sugarRange get-param sugarRange get-param metabolismRange get-param metabolismRange get-param visionRange get-param foresightRange [] [] ds []
end

to setup-agent [sr spr sm spm vr for xy imm dis cul]
  set sugar        sr
  set initSugar    sugar
  ifelse spice?
    [
    set spice        spr
    set initSpice    spice
    ]
    [
    set spice        0
    set initSpice    0
    ]
  set vision         vr
  set neighborhood   make-neighborhood vision
  set sugarMetabolismGenotype  sm
  set spiceMetabolismGenotype  spm
  set sugarGathered   0
  set spiceGathered   0
  set foresight       for
  ifelse (useR? or useS?)     [set maxage get-param ageRange] [set maxage 1000000]
  set age             0
  set sex             random 2
  set parentStep      0
  set fertileStart    get-param item 0 item sex fertileRanges
  set fertileEnd      get-param item 1 item sex fertileRanges
  ifelse (empty? xy)  [setup-xy] [setxy item 0 xy item 1 xy]
  set cultureTags     []
  ifelse (empty? cul) [repeat numCultureTags [set cultureTags lput random 2 cultureTags] ] [set cultureTags cul]
  set immuneTags      []
  ifelse (empty? imm) [repeat numImmuneTags [set immuneTags lput random 2 immuneTags] ] [set immuneTags imm]
  set immuneGenotype  immuneTags
  set infections      dis
  ifelse empty? infections
    [
    set sugarMetabolism sugarMetabolismGenotype
    set spiceMetabolism spiceMetabolismGenotype
    ]
    [
    set sugarMetabolism sugarMetabolismGenotype + max [fever] of turtle-set infections
    set spiceMetabolism spiceMetabolismGenotype + max [fever] of turtle-set infections
    ]
  set children        []
  set-color
  if spice?           [set-welfareMRS]
end

to setup-diseases
  set diseaseTags   []
  repeat (random numDiseaseTags) + 1 [set diseaseTags lput random 2 diseaseTags]
  ifelse diseaseSeverity = 0 [set fever 0] [set fever get-param list 1 diseaseSeverity]
end

to setup-xy
  let s 0
  let x 0
  let y 0
  ifelse agentLayout = 0 
    [set s world-width] 
    [
    ifelse agentLayout = 1 
      [set s ceiling sqrt (numAgents + 100)]
      [set s ceiling sqrt ((numAgents / 2) + 100)]
    ]
  set x random s
  set y random s
  if (agentLayout = 2 and random 2 = 0) [set x x - s set y y - s ]
  setxy (x + min-pxcor) (y + min-pycor)
  if (any? other agents-here) [setup-xy]
end

to my-setup-plots
  set-current-plot "Agents"
  set-plot-y-range 0 count agents
  set-current-plot "Line"
  ifelse maxForesight != 0
    [
    set-plot-y-range maxForesight * 0.9 / 2 maxForesight * 1.1 / 2
    ]
    [
    set-plot-y-range 0 max list last visionRange last metabolismRange
    ]
  set-current-plot "Histogram"
  set-current-plot "Scatter"
  if useT? [set-plot-y-range 0.5 1.5]
  set-current-plot "Histogram"
  ifelse useK? 
    [
    set-plot-x-range 0 numCultureTags
    set-histogram-num-bars numCultureTags
    ] 
  [set-histogram-num-bars 10]
end 

to setup-patches
  let s 0
  let t 0
  set s (word
"111111111111111111111111111112222222222111111111111"
"111111111111111111111111111222222222222222111111111"
"111111111111111111111111112222222222222222221111111"
"111111111111111111111111122222222222222222222211111"
"111111111111111111111111222222222222222222222221111"
"111110000000111111111111222222222223332222222222111"
"111110000000001111111111222222223333333332222222111"
"111110000000000111111112222222333333333333222222211"
"111110000000000111111112222223333333333333322222211"
"111110000000000011111112222223333333333333332222221"
"111110000000000011111122222233333344444333333222221"
"111110000000000111111122222233333444444433333222221"
"111111000000000111111122222333334444444443333222222"
"111111000000001111111222222333334444444443333322222"
"111111100000011111111222222333334444444443333322222"
"111111111001111111111222222333334444444443333322222"
"111111111111111111111222222333334444444443333222222"
"111111111111111111112222222333333444444433333222222"
"111111111111111111112222222233333344444333333222222"
"111111111111111111122222222233333333333333332222222"
"111111111111111112222222222223333333333333332222222"
"111111111111122222222222222223333333333333322222222"
"111111111122222222222222222222233333333332222222221"
"111111122222222222222222222222222333333222222222221"
"111122222222222222222222222222222222222222222222211"
"111222222222222222222222222222222222222222222222111"
"112222222222222222222222222222222222222222222221111"
"122222222222333333222222222222222222222222221111111"
"122222222233333333332222222222222222222221111111111"
"222222223333333333333322222222222222221111111111111"
"222222233333333333333322222222222211111111111111111"
"222222233333333333333332222222221111111111111111111"
"222222333333444443333332222222211111111111111111111"
"222222333334444444333333222222211111111111111111111"
"222222333344444444433333222222111111111111111111111"
"222223333344444444433333222222111111111100111111111"
"222223333344444444433333222222111111110000001111111"
"222223333344444444433333222222111111100000000111111"
"222222333344444444433333222221111111000000000111111"
"122222333334444444333332222221111111000000000011111"
"122222333333444443333332222221111110000000000011111"
"122222233333333333333322222211111110000000000011111"
"112222223333333333333322222211111111000000000011111"
"112222222333333333333222222211111111000000000011111"
"111222222233333333322222222111111111100000000011111"
"111222222222233322222222222111111111111000000011111"
"111122222222222222222222222111111111111111111111111"
"111112222222222222222222221111111111111111111111111"
"111111122222222222222222211111111111111111111111111"
"111111111222222222222222111111111111111111111111111"
"111111111111222222222211111111111111111111111111111"
)
  ask patches [set-maxpsugar read-from-string item ((25 - pycor) * 51 + (pxcor + 25)) s set pollution 1]

  if spice? [set t (word
reverse "111111111111111111111111111112222222222111111111111"
reverse "111111111111111111111111111222222222222222111111111"
reverse "111111111111111111111111112222222222222222221111111"
reverse "111111111111111111111111122222222222222222222211111"
reverse "111111111111111111111111222222222222222222222221111"
reverse "111110000000111111111111222222222223332222222222111"
reverse "111110000000001111111111222222223333333332222222111"
reverse "111110000000000111111112222222333333333333222222211"
reverse "111110000000000111111112222223333333333333322222211"
reverse "111110000000000011111112222223333333333333332222221"
reverse "111110000000000011111122222233333344444333333222221"
reverse "111110000000000111111122222233333444444433333222221"
reverse "111111000000000111111122222333334444444443333222222"
reverse "111111000000001111111222222333334444444443333322222"
reverse "111111100000011111111222222333334444444443333322222"
reverse "111111111001111111111222222333334444444443333322222"
reverse "111111111111111111111222222333334444444443333222222"
reverse "111111111111111111112222222333333444444433333222222"
reverse "111111111111111111112222222233333344444333333222222"
reverse "111111111111111111122222222233333333333333332222222"
reverse "111111111111111112222222222223333333333333332222222"
reverse "111111111111122222222222222223333333333333322222222"
reverse "111111111122222222222222222222233333333332222222221"
reverse "111111122222222222222222222222222333333222222222221"
reverse "111122222222222222222222222222222222222222222222211"
reverse "111222222222222222222222222222222222222222222222111"
reverse "112222222222222222222222222222222222222222222221111"
reverse "122222222222333333222222222222222222222222221111111"
reverse "122222222233333333332222222222222222222221111111111"
reverse "222222223333333333333322222222222222221111111111111"
reverse "222222233333333333333322222222222211111111111111111"
reverse "222222233333333333333332222222221111111111111111111"
reverse "222222333333444443333332222222211111111111111111111"
reverse "222222333334444444333333222222211111111111111111111"
reverse "222222333344444444433333222222111111111111111111111"
reverse "222223333344444444433333222222111111111100111111111"
reverse "222223333344444444433333222222111111110000001111111"
reverse "222223333344444444433333222222111111100000000111111"
reverse "222222333344444444433333222221111111000000000111111"
reverse "122222333334444444333332222221111111000000000011111"
reverse "122222333333444443333332222221111110000000000011111"
reverse "122222233333333333333322222211111110000000000011111"
reverse "112222223333333333333322222211111111000000000011111"
reverse "112222222333333333333222222211111111000000000011111"
reverse "111222222233333333322222222111111111100000000011111"
reverse "111222222222233322222222222111111111111000000011111"
reverse "111122222222222222222222222111111111111111111111111"
reverse "111112222222222222222222221111111111111111111111111"
reverse "111111122222222222222222211111111111111111111111111"
reverse "111111111222222222222222111111111111111111111111111"
reverse "111111111111222222222211111111111111111111111111111"
)
  ask patches [set-maxpspice read-from-string item ((25 - pycor) * 51 + (pxcor + 25)) t]
  ]
end

to set-psugar [s] ; Utility to set this patches psugar to s, checking s for neg and maxsugar
  set psugar max list 0 (min list s maxpsugar)
  set-pcolor
end

to set-maxpsugar [s] ; Utility to set this patches maxpsugar to s
  set maxpsugar s
  set-psugar s
end

to set-pspice [t] ; Utility to set this patches pspice to t
  set pspice max list 0 (min list t maxpspice)
  set-pcolor
end

to set-maxpspice [t] ; Utility to set this patches maxpspice to t
  set maxpspice t
  set-pspice t
end

to set-pcolor
  if showScape = "white" [set pcolor white]
  if showScape = "sugar and spice"
    [
    ifelse psugar > pspice [set pcolor scapeColor + 4 - psugar]
      [
      set pcolor scapeColor + 4 - pspice
      ]
    ]
  if showScape = "pollution" [set pcolor scale-color brown pollution 50 0 stop]
end

to set-welfareMRS ; Utility to update agent welfare and MRS
  set welfare find-welfare sugar sugarMetabolism spice spiceMetabolism foresight
  set MRS find-MRS sugar sugarMetabolism spice spiceMetabolism foresight
end

to-report shuffle-agents [a] ; Utility from Seth for randomizing an agent set
  let shuffled 0
  set shuffled [self] of a
  set shuffled sort-by [random 2 = 0] shuffled
  report shuffled
end

to-report neg [n] ; Utility for unary negation
  report 0 - n
end

to-report find-welfare [sug sugm spi spim for] ; Utility to find new welfare after a potential move
  let m1 sugm
  let m2 spim
  let mt (sugm + spim)
  let w1 max list 0 (sug - (for + 1) * sugm)
  let w2 max list 0 (spi - (for + 1) * spim)
  report (w1 ^ (m1 / mt)) * (w2 ^ (m2 / mt))
end

to-report find-MRS [sug sugm spi spim for] ; Utility to find new MRS after a potential trade
  report (spi / spim) / (sug / sugm)
end

to-report find-minhamdist [dis] ; Utility to find the best fit of string dis to string immuneTags
  let l 0
  let m 0
  let n 0
  let n0 0
  let dist 0
  let strain []
  let hamDist []
  set strain [diseaseTags] of dis
  set l length strain
  set m length immuneTags
  set n0 0
  set dist 0
  repeat  m - l + 1
    [
    set n 0
    set dist 0
    repeat l
      [
      if item n strain != item (n + n0) immuneTags [set dist dist + 1]
      set n n + 1
      ]
    set n0 n0 + 1
    set hamDist lput dist hamDist
    ]
  report position min hamDist hamDist
end

to-report get-param [p] ; Utility to return a random number between values in a 2 element list
  report first p + random (last p - first p + 1)
end

to-report make-neighborhood [n]
  let i 0
  let l 0
  set i 1
  set l []
  while [ i <= n ] 
    [
    set l lput (list 0 i) l
    set l lput (list i 0) l
    set l lput (list 0 (0 - i)) l
    set l lput (list (0 - i) 0) l
    set i i + 1
    ]
  report l
end
@#$#@#$#@
GRAPHICS-WINDOW
548
10
989
472
25
25
8.451
1
10
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

BUTTON
328
10
406
43
Setup
setup false
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
408
10
471
43
Go!
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
473
10
536
43
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
997
10
1300
160
Agents
Time
Count
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"Infected" 1.0 0 -13840069 true "" ""
"Agents" 1.0 0 -16777216 true "" ""

PLOT
997
308
1401
469
Line
ticks
Value
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Vision" 1.0 0 -16777216 true "" ""
"Sugar Metabolism" 1.0 0 -2674135 true "" ""
"Spice Metabolism" 1.0 0 -955883 true "" ""
"Foresight" 1.0 0 -1184463 true "" ""
"Lenders" 1.0 0 -5825686 true "" ""
"Lender/Borrowers" 1.0 0 -8630108 true "" ""
"Borrowers" 1.0 0 -2064490 true "" ""
"Trade Volume" 1.0 0 -13345367 true "" ""
"Black" 1.0 0 -7500403 false "" ""

PLOT
997
159
1349
309
Histogram
Wealth/Ages/Tags
Turtles
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Wealth" 10.0 1 -2674135 true "" ""
"Ages" 1.0 1 -10899396 true "" ""
"Tags" 1.0 1 -13345367 true "" ""

CHOOSER
10
10
239
55
Presets
Presets
"1: Movement: Navigating the Sugarscape" "2: Migration and Emergence" "3: Reproduction: Population Dynamics" "4: Two Resources: Sugar and Spice" "5: Trade: Decentralised Marketplace" "6: Loans: Emergence of Hierarchy" "7: Disease: Immunity and Transmission" "8: Life on the Brink"
0

SLIDER
9
87
182
120
numAgents
numAgents
0
800
400
50
1
NIL
HORIZONTAL

SWITCH
189
371
292
404
useK?
useK?
1
1
-1000

SLIDER
189
87
299
120
minMetabolism
minMetabolism
0
maxMetabolism
1
1
1
NIL
HORIZONTAL

SLIDER
298
87
408
120
maxMetabolism
maxMetabolism
minMetabolism
5
4
1
1
NIL
HORIZONTAL

SLIDER
189
122
299
155
minVision
minVision
0
maxVision
1
1
1
NIL
HORIZONTAL

SLIDER
298
122
408
155
maxVision
maxVision
minVision
10
6
1
1
NIL
HORIZONTAL

CHOOSER
189
248
292
293
replacementRule
replacementRule
"none" "R" "S"
0

SLIDER
189
157
299
190
minInitialSugar
minInitialSugar
5
maxInitialSugar
5
5
1
NIL
HORIZONTAL

SLIDER
298
157
408
190
maxInitialSugar
maxInitialSugar
minInitialSugar
100
25
5
1
NIL
HORIZONTAL

SLIDER
8
186
180
219
sugarGrowBackRate
sugarGrowBackRate
0
4
1
1
1
NIL
HORIZONTAL

TEXTBOX
11
70
161
88
Population Settings
11
0.0
1

TEXTBOX
192
70
342
88
Agent Settings
11
0.0
1

CHOOSER
9
122
182
167
distribution
distribution
"scatter" "corner"
0

TEXTBOX
13
170
163
188
Environment Settings
11
0.0
1

TEXTBOX
190
231
295
249
Replacement Settings
11
0.0
1

TEXTBOX
307
232
394
250
Trade Settings
11
0.0
1

SWITCH
305
282
408
315
useT?
useT?
1
1
-1000

SWITCH
305
248
408
281
spice?
spice?
1
1
-1000

PLOT
997
468
1337
618
Scatter
Time
Value
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Price" 1.0 2 -16777216 true "" ""
"1" 1.0 0 -2674135 false "" ""

SLIDER
8
221
180
254
spiceGrowBackRate
spiceGrowBackRate
0
4
0
1
1
NIL
HORIZONTAL

TEXTBOX
423
70
573
88
Graphical Settings
11
0.0
1

SWITCH
305
336
408
369
useL?
useL?
1
1
-1000

TEXTBOX
306
320
404
350
Lending Settings
11
0.0
1

CHOOSER
418
87
536
132
agentColors
agentColors
"red" "fertility" "culture" "sugar/spice" "lender/borrower" "infected"
0

SLIDER
305
372
408
405
interest
interest
0
0.5
0
0.05
1
NIL
HORIZONTAL

BUTTON
418
183
536
216
Show/Hide links
ifelse showlinks?\n[\nset showLinks? false\nask trades [set hidden? true]\nask loans [set hidden? true]\n]\n[\nset showLinks? true\nask trades [set hidden? false]\nask loans [set hidden? false]\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
194
409
344
427
Disease Settings
11
0.0
1

SWITCH
189
425
292
458
useE?
useE?
1
1
-1000

SLIDER
189
460
361
493
numDiseases
numDiseases
4
30
0
1
1
NIL
HORIZONTAL

TEXTBOX
191
354
286
372
Culture Settings
11
0.0
1

SLIDER
189
495
361
528
diseaseSeverity
diseaseSeverity
0
2
0
1
1
NIL
HORIZONTAL

SWITCH
8
436
98
469
useP?
useP?
1
1
-1000

SWITCH
8
506
98
539
useD?
useD?
1
1
-1000

TEXTBOX
11
419
161
437
Pollution Settings
11
0.0
1

SLIDER
8
471
180
504
pollutionRate
pollutionRate
0.00
1
0
0.1
1
NIL
HORIZONTAL

SLIDER
8
541
180
574
diffusionRate
diffusionRate
0
1
0
0.05
1
NIL
HORIZONTAL

SWITCH
189
315
292
348
useI?
useI?
1
1
-1000

TEXTBOX
190
299
295
317
Inheritance Settings
11
0.0
1

TEXTBOX
104
435
164
469
Note:\nSpice is a clean resource
9
0.0
1

BUTTON
248
10
326
43
Setup preset
setup true
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
8
343
123
376
useSeasons?
useSeasons?
1
1
-1000

SLIDER
8
379
180
412
seasonPeriod
seasonPeriod
10
100
10
10
1
NIL
HORIZONTAL

TEXTBOX
11
327
97
345
Season Settings
11
0.0
1

SLIDER
8
256
180
289
sugarGrowBackInterval
sugarGrowBackInterval
1
4
1
1
1
NIL
HORIZONTAL

SLIDER
8
291
180
324
spiceGrowBackInterval
spiceGrowBackInterval
1
4
1
1
1
NIL
HORIZONTAL

SLIDER
189
192
361
225
maxForesight
maxForesight
0
10
0
10
1
NIL
HORIZONTAL

CHOOSER
418
135
536
180
showScape
showScape
"sugar and spice" "white" "pollution"
0

@#$#@#$#@
## VERSION

For use with NetLogo 5.1

## WHAT IS IT?

A version of SugarScape, as presented in "Growing Artificial Societies" by Epstein and Axtell.  It builds on Owen Densmore's NetLogo community model to encompass all rules discussed in GAS with the exception of the combat rule (although trivial to include, it adds little value to the model).

## HOW IT WORKS

Patches represent a toroidal world with "sugar" (representing wealth) deposited in two roughly circular regons or "hills" of increasing sugar density.  Agents and patches follow a number of rules designed to deomonstrate various properties that emerge from this simple artificial society.

Agent rules  
M: Enables agents to move about the Sugarscape, eat sugar and metabolise  
P: Causes agents to leave pollution where they eat and metabolise  
R: Replaces dead agents with a new randomly generated agent  
S: Enables sexual reproduction between agents  
I: Enables accumulated wealth to be passed down to children on an agents death   
K: Enables transmission of cultural information  
T: Enables agents to engage in trade between two resources  
L: Enables agents to borrow sugar for reproduction  
E: Enables agents to generate an immune response to, and transmit disease

Patch rules  
G: Causes sugar to grow back at each patch  
D: Causes accumulated pollution to diffuse to adjacent patches  
Seasons: Half of the Sugarscape regrows at a much lower rate, and periodically switches.

## HOW TO USE IT

The chooser labelled "Presets" offers a variety of settings to explore the scope of the Sugarscape. To set model parameters to the presets, click "Setup Preset".

## THINGS TO TRY

The Sugarscape can be home to a colourful variety of emergant structure and behavior. How to use the interface, and information on the different presets, and effects that can be seen are discussed more in a document which can be found here:

http://www2.le.ac.uk/departments/interdisciplinary-science/research/the-sugarscape

## EXTENDING THE MODEL

This version of Sugarscape has been very successful in achieving the same results as those presented in GAS. However, several observations have not been successfully recreated, and it is unclear how GAS implimented some combinations of rules, such as L in the two resources landscape.

Discrepancies are discussed more thoroughly here:

http://www2.le.ac.uk/departments/interdisciplinary-science/research/replicating-sugarscape

## CREDITS AND REFERENCES

Owen Densmore, Sugarscape (2003 NetLogo community model)  
JM Epstein and R Axtell, Growing Artificial Societies (MIT Press, 1996)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
