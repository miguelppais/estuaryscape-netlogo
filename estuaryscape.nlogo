;;ESTUARYSCAPE MODEL

extensions [gis]

;; Parameters not in the interface

breed [fishes fish]

globals[
  the-map
  non-land-patches       ; an agentset of patches that excludes land patches, to avoid unnecessary calculations happening in land
]

fishes-own [
  energy
  eating                  ; prey type the fish is currently eating ????
  move-decision           ; decision whether to move or stay, by analysing current patch (for synchronization)
  species
  sex
  reserve                 ; energy reserve
  age
  stage ;juv or adult
  age-at-maturity
  max-age
  nr-gametes              ; nr of gametes produced by adults
  feeding-rate
  assimilation-rate
  reproduction-threshold
  ]

patches-own [
  patch-id ; unique number to identify each patch
  worms
  bivalves
  plankton
  habitat ; canal or mudflat
  red.eggs ; red fish eggs
  green.eggs ; green fish eggs
  ]

;; Model setup and schedule

to startup
  load-example-map
  set map-file "map.asc"
end

to setup
  clear-all
  load-map
  setup-environment
  setup-fishes
  reset-ticks
end

to go
  if not any? fishes [
    stop
  ]
  ask fishes [
    grow                              ; die if too old, increase age otherwise (also controls life stage change)
    pay-maintenance                                                    ; pay maintenance-costs or die!
    set move-decision "undecided"                                      ; when the turn starts, every fish is undecided
    scan-surroundings
    move                                                               ; move or stay based on the scan decision
    eat                                                                ; fishes eat prey
  ]
  egg-development     ; eggs age advances
  hatch-eggs          ; eggs that reach full development hatch
  fish-reproduction  ; fish reproduce
  regrow-prey        ; prey grows back
  diffuse worms 0.01      ; prey move to adjacent patches
  diffuse bivalves 0.01
  diffuse plankton 0.3
  tick
end


;; FISH-RELATED PROCEDURES



to setup-fishes
  create-fishes number-of-fishes [
    move-to-and-jitter one-of non-land-patches ; place fishes on a random patch that is not land and jitter
    set color one-of [red green]
    set sex one-of ["male" "female"]
    set shape "fish"
    set energy energy-reserve-size - random-float (energy-reserve-size * 0.1) ; individual variability in initial energy from top 10% of max reserve size
  ]

  ask fishes with [color = red] [                                  ; setup red fish attributes
    set species "red"
    set age-at-maturity age-at-maturity-red * 365                 ; convert age to days (ticks)
    set max-age max-age-red * 365
    set feeding-rate feeding-rate-red
    set assimilation-rate assimilation-rate-red
    set reproduction-threshold reproduction-threshold-red
  ]

  ask fishes with [color = green] [                                 ; setup green fish attributes
    set species "green"
    set age-at-maturity age-at-maturity-green * 365                ; convert age to days (ticks)
    set max-age max-age-green * 365
    set feeding-rate feeding-rate-green
    set assimilation-rate assimilation-rate-green
    set reproduction-threshold reproduction-threshold-green
  ]

  ask fishes [
    set age random-normal (max-age / 2) ((max-age / 2) * 0.3)     ; distribute ages with the mean as half the life expectancy and a CV of 30%
    if age < 0 [set age 0]
    ifelse age >= age-at-maturity [set stage "adult"] [set stage "juvenile"]
    set size 0.3 + ((age / max-age) * 0.3)                        ; scale the size according to age
  ]

end

to move-to-and-jitter [p] ; moves to a patch and jitters fish coordinates within patch for easier visualization
  let x [pxcor] of p
  let y [pycor] of p
  setxy (x + random-float-between -0.49 0.49) (y + random-float-between -0.49 0.49)
end



to pay-maintenance
  set energy energy - maintenance-cost
  if energy <= 0 [die] ; fish die if they can't pay maintenance

end



to grow
  if age >= max-age [die]
  set age age + 1
  if age >= age-at-maturity [set stage "adult"]
  set size 0.3 + ((age / max-age) * 0.3)                        ; scale the size according to age
end

;; fishes decide whether to stay or move based on the conditions of the current patch

to scan-surroundings

  ifelse (stage = "adult" and energy > reproduction-threshold) [               ; thought process of horny adults
    ifelse any? fishes-here with [sex != [sex] of myself and species = [species] of myself] [
      set move-decision "stay"
    ] [
    set move-decision "move"
    ] ; end ifelse

  ] [

  if eating = "worms" []                                                        ; thought process of hungry adults

  ]   ; end ifelse

 end

to move

  ifelse move-decision = "stay" [
   set energy energy - small-movement-cost
  ] [
   set energy energy - large-movement-cost
   move-to-and-jitter one-of neighbors with [habitat != "land"]
  ]

end

;; fishes eat prey

to eat                                                     ; consider having a fitness measure controlling who gets the best prey
  let prey-amount 0
  ;; check to make sure there is worms here
  if ( worms >= energy-gain-from-worms ) [
    ;; increment the fishes's energy
    set energy energy + energy-gain-from-worms
    ;; decrement the worms
    set worms worms - energy-gain-from-worms
    recolor-patches
  ]
end


; Apt fish reproduce

to fish-reproduction     ; observer procedure
  ask non-land-patches with [length (remove-duplicates [sex] of fishes-here with [species = "green" and stage = "adult" and energy > reproduction-threshold]) = 2] [  ; patches with both sexes of green adults fit for reproduction
    let green-reproductive-adults fishes-here with [species = "green" and stage = "adult" and energy > reproduction-threshold]
    ask green-reproductive-adults [
      set nr-gametes floor (energy - reproduction-threshold) / cost-per-gamete     ; the number of eggs procuced equals the surplus energy divided by the energetic cost per gamete
      set energy (energy - (nr-gametes * cost-per-gamete))                         ; energy of the gametes produced is removed from the fish
    ]
    let green-female-gametes sum [nr-gametes] of green-reproductive-adults with [sex = "female"]
    let green-male-gametes sum [nr-gametes] of green-reproductive-adults with [sex = "male"]
    set green.eggs fput (min list green-female-gametes green-male-gametes) green.eggs ; the minimum number between female and male gametes is picked as the nr of eggs (two are needed). The other gametes are wasted.
    ask green-reproductive-adults [set nr-gametes 0]
  ]

  ask non-land-patches with [length (remove-duplicates [sex] of fishes-here with [species = "red" and stage = "adult" and energy > reproduction-threshold]) = 2] [  ; patches with both sexes of red adults fit for reproduction
    let red-reproductive-adults fishes-here with [species = "red" and stage = "adult" and energy > reproduction-threshold]
    ask red-reproductive-adults [
      set nr-gametes floor (energy - reproduction-threshold) / cost-per-gamete     ; the number of eggs procuced equals the surplus energy divided by the energetic cost per gamete
      set energy (energy - (nr-gametes * cost-per-gamete))
    ]
    let red-female-gametes sum [nr-gametes] of red-reproductive-adults with [sex = "female"]
    let red-male-gametes sum [nr-gametes] of red-reproductive-adults with [sex = "male"]
    set red.eggs sentence red.eggs (n-values (min list red-female-gametes red-male-gametes) [0])
    ask red-reproductive-adults [set nr-gametes 0]
  ]


end



;; PATCH-RELATED PROCEDURES



;; create the world

to load-map
  set the-map gis:load-dataset map-file
  gis:apply-raster the-map pcolor
  ask patches [
    if pcolor = 96 [set habitat "canal"]
    if pcolor = 37 [set habitat "mudflat"]
    if pcolor = green [set habitat "land"]
  ]
  set non-land-patches patches with [habitat != "land"]
end

to setup-environment      ; observer procedure
  ask non-land-patches [
    set green.eggs []                    ; eggs are initialized as empty lists
    set red.eggs []
  ]
  ask non-land-patches with [habitat = "mudflat"] [
    set worms random max-worms-mudflat
    set bivalves random max-bivalves-mudflat
    set plankton random max-plankton-mudflat
  ]
  ask non-land-patches with [habitat = "canal"] [

  ]
end

to egg-development             ; observer procedure
  ask non-land-patches [
    set green.eggs map [? + 1] green.eggs
    set red.eggs map [? + 1] red.eggs
  ]
end


to hatch-eggs                  ; observer procedure
  ask non-land-patches with [(length (filter [? >= days-until-hatch] green.eggs) > 0) or (length (filter [? >= days-until-hatch] red.eggs) > 0)] [
  let nr-green-eggs length (filter [? >= days-until-hatch] green.eggs)
  let nr-red-eggs length (filter [? >= days-until-hatch] red.eggs)
  if nr-green-eggs > 0 [
    set green.eggs remove days-until-hatch green.eggs

    sprout-fishes nr-green-eggs [
      set sex one-of ["male" "female"]
      set shape "fish"
      set energy energy-reserve-size - random-float (energy-reserve-size * 0.1)
      set species "green"
      set age 0
      set size 0.3 + ((age / max-age) * 0.3)                        ; scale the size according to age
      set age-at-maturity age-at-maturity-green * 365                ; convert age to days (ticks)
      set max-age max-age-green * 365
      set feeding-rate feeding-rate-green
      set assimilation-rate assimilation-rate-green
      set reproduction-threshold reproduction-threshold-green
      move-to-and-jitter one-of non-land-patches    ; fish juveniles settle at a random non-land location
    ]
    ]
  if nr-red-eggs > 0 [
    set red.eggs remove days-until-hatch red.eggs

    sprout-fishes nr-red-eggs [
      set sex one-of ["male" "female"]
      set shape "fish"
      set energy energy-reserve-size - random-float (energy-reserve-size * 0.1)
      set species "red"
      set age 0
      set size 0.3 + ((age / max-age) * 0.3)                        ; scale the size according to age
      set age-at-maturity age-at-maturity-red * 365                ; convert age to days (ticks)
      set max-age max-age-red * 365
      set feeding-rate feeding-rate-red
      set assimilation-rate assimilation-rate-red
      set reproduction-threshold reproduction-threshold-red
      move-to-and-jitter one-of non-land-patches    ; fish juveniles settle at a random non-land location
    ]
  ]
  ]
end



;; regrow prey
to regrow-prey              ; obsever procedure
  ask non-land-patches [
    set worms worms + (worms-regrowth-rate * worms)
    set bivalves bivalves + (bivalves-regrowth-rate * bivalves)
    set plankton plankton + (plankton-regrowth-rate * plankton)

    ; limit the amount of prey to the carrying capacity of the habitat

    if habitat = "muflat" [
      if worms > max-worms-mudflat [set worms max-worms-mudflat]
      if bivalves > max-bivalves-mudflat [set bivalves max-bivalves-mudflat]
      if plankton > max-plankton-mudflat [set plankton max-plankton-mudflat]
    ]
    if habitat = "canal" [
      if worms > max-worms-canal [set worms max-worms-canal]
      if bivalves > max-bivalves-canal [set bivalves max-bivalves-canal]
      if plankton > max-plankton-canal [set plankton max-plankton-canal]
    ]
  ]
end

; PREY REPORTERS

to-report worms-value
report energy-gain-from-worms * weight-per-worm
end

to-report bivalves-value
report energy-gain-from-bivalves * weight-per-bivalve
end

to-report plankton-value
report energy-gain-from-plankton * weight-per-plankton
end


;; recolor the worms to indicate how much has been eaten
to recolor-patches   ; alternative visualization to look at prey abundances?  TO DO

end

; PLOTTING AND OUTPUTS





;; MAP EDITOR

to draw-canals
  if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ask patch mouse-xcor mouse-ycor
        [ set pcolor 96
          display ]
    ]
end


to draw-mudflats
  if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ask patch mouse-xcor mouse-ycor
        [ set pcolor 37
          display ]
    ]
end

to erase-map
   if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ask patch mouse-xcor mouse-ycor
        [ set pcolor black
          display ]
    ]
end

to fill-land
  ask patches with [pcolor = black] [
   set pcolor green
  ]
end


;; MAPS ;;



to load-example-map

set the-map
[
55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 96 96 96 96 96 96 96 96 96 96 96 96 96 55
55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 96 96 96 96 96 96 96 96 96 96 96 96 55 55
55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 96 96 96 96 96 96 96 96 96 96 96 96 55 55
55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 96 96 96 96 96 96 96 96 96 96 96 96 96 55 55
55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 96 96 96 96 96 96 96 96 96 96 96 96 55 55 55
55 55 55 55 55 55 55 37 37 37 37 37 37 37 37 37 37 37 37 37 55 55 55 55 55 55 55 55 55 55 55 55 55 37 96 96 96 96 96 96 96 96 96 96 96 96 55 55 55 55
55 55 55 55 55 55 37 96 96 96 37 37 37 37 37 37 37 37 37 37 37 55 55 55 55 55 55 55 55 55 55 55 37 37 96 96 96 96 96 96 96 96 96 96 96 55 55 55 55 55
55 55 55 55 55 55 37 37 37 96 96 37 37 37 37 37 96 96 37 37 37 37 37 37 37 37 55 55 55 55 37 37 37 96 96 96 96 96 96 96 96 96 96 96 55 55 55 55 55 55
55 55 55 55 55 55 37 37 37 37 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 55 55 55 55 55 55
55 55 55 55 55 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 37 55 55 55 55 55 55
55 55 55 55 55 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 55 55 55 55 55 55
55 55 55 55 55 37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 55 55 55 55 55 55
55 55 55 55 55 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 55 55 55 55 55 55
55 55 55 55 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 55 55 55 55 55 55
55 55 55 55 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 55 55 55 55 55
55 55 55 55 37 37 37 37 37 37 96 96 96 96 37 37 37 96 96 96 96 96 96 96 96 96 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 55 55 55 55 55
55 55 55 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 55 55 55 55 55
55 55 55 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 55 55 55 55
55 55 37 37 37 96 96 96 37 37 37 37 37 37 37 96 96 96 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 55 55 55 55
55 55 37 96 96 96 96 96 37 37 37 37 37 96 96 96 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 55 55 55
55 55 37 96 96 96 37 37 37 37 37 96 96 96 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 37 96 96 96 96 96 37 37 37 37 37 55 55 55
55 37 37 96 37 37 37 37 37 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 37 37 96 96 96 96 96 96 37 37 37 37 37 55 55
55 37 37 37 37 37 37 37 37 96 96 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 37 37 96 96 96 96 96 96 96 37 37 37 37 55 55
55 37 37 37 37 37 37 96 37 37 96 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 96 96 96 96 37 96 96 37 37 37 55 55
55 37 37 37 37 37 37 96 96 96 96 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 96 96 96 96 37 37 96 96 37 37 37 37
55 37 37 37 37 37 96 96 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 96 96 96 96 96 37 37 96 37 37 96 37
37 37 37 37 37 37 96 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 96 96 96 96 37 37 96 96 37 96 37
37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 96 96 96 37 37 37 96 96 96 37
37 37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 96 96 96 37 37 37 37 37 37 37
37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 96 96 96 37 37 37 37 37 37 37
37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 96 96 96 96 37 37 37 37 37
37 37 37 37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 37 37 37 37
37 37 37 37 37 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 37 37 37
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 37 37
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 37
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 96 96 96 96 96
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 96 37 96 96 96 96 96
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 96 96 37 37 37 96 96 96
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 96 37 37 37 37 37 96 96
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 96 37 37 37 37 37 37 96
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 37 96 37 37 37 37 37 37 96
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 96 37 37 37 37 37 37 37
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 96 37 37 37 37 37 37 37
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 37 37 37 37 37 37
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 96 96 37 37 37 37 37
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 96 37 37 37 37 37
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 37 37 55 55 55 55 55 55 37 37 37 96 96 96 37 37 55 55 55
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 37 37 37 37 55 55 55 55 55 55 55 55 37 37 37 96 37 37 37 55 55 55 55
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 37 55 55 55 55 55 55 55 55 55 55 55 55 55 55 37 37 37 55 55 55 55 55 55
96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 96 37 37 37 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 37 55 55 55 55 55 55 55
]

ask patches [set pcolor item (pxcor - ((pycor - 49) * 50)) the-map
  if pcolor = 96 [set habitat "canal"]
  if pcolor = 37 [set habitat "mudflat"]
  if pcolor = 55 [set habitat "land"]
]

gis:set-world-envelope (list min-pxcor max-pxcor min-pycor max-pycor)

set the-map gis:patch-dataset pcolor

gis:store-dataset the-map "map"

user-message "Welcome! The default map has been loaded and saved as a map.asc raster file in your model folder."

end


; USEFUL REPORTERS

to-report random-float-between [a b]
  report a + random-float (b - a)
end

to-report random-between [a b]
  report a + random (b - a)
end
@#$#@#$#@
GRAPHICS-WINDOW
255
10
765
541
-1
-1
10.0
1
5
1
1
1
0
0
0
1
0
49
0
49
1
1
1
ticks
30.0

BUTTON
15
15
78
60
NIL
setup
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
80
15
167
60
go / pause
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

SLIDER
15
70
240
103
number-of-fishes
number-of-fishes
10
500
500
5
1
NIL
HORIZONTAL

SLIDER
245
705
535
738
worms-regrowth-rate
worms-regrowth-rate
0
100
20
1
1
/ worm / day
HORIZONTAL

SLIDER
20
705
245
738
energy-gain-from-worms
energy-gain-from-worms
0
30
17
0.5
1
per g
HORIZONTAL

SLIDER
1050
470
1222
503
large-movement-cost
large-movement-cost
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
245
750
535
783
bivalves-regrowth-rate
bivalves-regrowth-rate
0
100
20
1
1
/ bivalve / day
HORIZONTAL

SLIDER
245
795
535
828
plankton-regrowth-rate
plankton-regrowth-rate
0
20000
7000
100
1
/ plankton / day
HORIZONTAL

SLIDER
20
750
245
783
energy-gain-from-bivalves
energy-gain-from-bivalves
0
30
10
0.5
1
per g
HORIZONTAL

SLIDER
20
795
245
828
energy-gain-from-plankton
energy-gain-from-plankton
0
100
50
1
1
per g
HORIZONTAL

SLIDER
795
60
987
93
age-at-maturity-red
age-at-maturity-red
1
30
10
1
1
years
HORIZONTAL

SLIDER
1040
60
1242
93
age-at-maturity-green
age-at-maturity-green
1
30
10
1
1
years
HORIZONTAL

SLIDER
795
110
967
143
max-age-red
max-age-red
1
30
15
1
1
years
HORIZONTAL

SLIDER
1040
110
1212
143
max-age-green
max-age-green
1
30
15
1
1
years
HORIZONTAL

SLIDER
795
165
992
198
feeding-rate-red
feeding-rate-red
0
100
50
1
1
g per day
HORIZONTAL

SLIDER
1040
165
1252
198
feeding-rate-green
feeding-rate-green
0
100
50
1
1
g per day
HORIZONTAL

SLIDER
795
210
972
243
assimilation-rate-red
assimilation-rate-red
0
100
50
5
1
%
HORIZONTAL

SLIDER
1045
210
1237
243
assimilation-rate-green
assimilation-rate-green
0
100
50
5
1
%
HORIZONTAL

SLIDER
1050
505
1222
538
maintenance-cost
maintenance-cost
0
100
20
1
1
NIL
HORIZONTAL

SLIDER
1050
435
1222
468
small-movement-cost
small-movement-cost
0
100
15
1
1
NIL
HORIZONTAL

SLIDER
790
255
987
288
reproduction-threshold-red
reproduction-threshold-red
0
1000
800
10
1
NIL
HORIZONTAL

SLIDER
1040
255
1252
288
reproduction-threshold-green
reproduction-threshold-green
0
1000
800
10
1
NIL
HORIZONTAL

SLIDER
825
370
1000
403
cost-per-gamete
cost-per-gamete
0.0005
0.005
0.005
0.0005
1
NIL
HORIZONTAL

SLIDER
825
405
1000
438
days-until-hatch
days-until-hatch
1
30
10
1
1
NIL
HORIZONTAL

SLIDER
795
295
967
328
egg-mortality-red
egg-mortality-red
0
100
40
5
1
%
HORIZONTAL

SLIDER
1045
295
1222
328
egg-mortality-green
egg-mortality-green
0
100
40
5
1
%
HORIZONTAL

SLIDER
1050
370
1222
403
energy-reserve-size
energy-reserve-size
10
1500
1500
10
1
NIL
HORIZONTAL

SLIDER
535
705
720
738
weight-per-worm
weight-per-worm
0.01
0.3
0.08
0.01
1
g
HORIZONTAL

SLIDER
535
750
720
783
weight-per-bivalve
weight-per-bivalve
0.01
0.5
0.15
0.01
1
g
HORIZONTAL

SLIDER
535
795
720
828
weight-per-plankton
weight-per-plankton
0.00001
0.0001
4.0E-5
0.00001
1
g
HORIZONTAL

SLIDER
817
705
989
738
max-worms-mudflat
max-worms-mudflat
0
500
500
10
1
NIL
HORIZONTAL

SLIDER
817
750
989
783
max-bivalves-mudflat
max-bivalves-mudflat
0
500
190
10
1
NIL
HORIZONTAL

SLIDER
817
795
989
828
max-plankton-mudflat
max-plankton-mudflat
0
20000
13500
100
1
NIL
HORIZONTAL

SLIDER
987
705
1159
738
max-worms-canal
max-worms-canal
0
500
60
10
1
NIL
HORIZONTAL

SLIDER
987
750
1159
783
max-bivalves-canal
max-bivalves-canal
0
500
350
10
1
NIL
HORIZONTAL

SLIDER
987
795
1159
828
max-plankton-canal
max-plankton-canal
0
20000
13500
100
1
NIL
HORIZONTAL

BUTTON
1325
100
1430
133
Draw canals
draw-canals
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
1325
140
1432
173
Draw mudflats
draw-mudflats
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
1325
220
1580
253
Fill empty patches with land
fill-land
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
1325
180
1430
213
ERASER
erase-map
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
1495
60
1577
93
Save map
gis:set-world-envelope (list min-pxcor max-pxcor min-pycor max-pycor)\nset the-map gis:patch-dataset pcolor\ngis:store-dataset the-map user-input \"The map will be stored as an .asc file. If the file exists, it will be overwritten. Pick a file name (exclude extension).\"
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
1415
60
1497
93
Load map
load-map
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
1325
60
1417
93
Clean slate
ask patches [set pcolor black]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
1325
260
1580
320
map-file
map.asc
1
0
String

PLOT
15
115
215
265
Fish populations
Days
Nr of fish
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Red" 1.0 0 -2674135 true "" "plot count turtles with [species = \"red\"]"
"Green" 1.0 0 -10899396 true "" "plot count turtles with [species = \"green\"]"

PLOT
15
285
215
405
Red age distribution
Age (years)
Nr of fish
0.0
30.0
0.0
10.0
true
false
"" ""
PENS
"Red" 1.0 1 -2674135 true "" "histogram [floor (age / 365)] of fishes with [species = \"red\"]"

PLOT
15
405
215
525
Green age distribution
Age (years)
Nr. of fish
0.0
30.0
0.0
10.0
true
false
"" ""
PENS
"Green" 1.0 1 -10899396 true "" "histogram [floor (age / 365)] of fishes with [species = \"green\"]"

BUTTON
1070
20
1167
53
Same as red
set age-at-maturity-green age-at-maturity-red\nset max-age-green max-age-red\nset feeding-rate-green feeding-rate-red\nset assimilation-rate-green assimilation-rate-red\nset reproduction-threshold-green reproduction-threshold-red\nset egg-mortality-green egg-mortality-red
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
720
705
815
750
worms value
worms-value
2
1
11

MONITOR
720
750
815
795
bivalves value
bivalves-value
17
1
11

MONITOR
720
795
815
840
plankton value
plankton-value
17
1
11

TEXTBOX
717
685
827
703
Energy per prey item
11
0.0
1

TEXTBOX
937
685
1087
703
CARRYING CAPACITY
11
0.0
1

TEXTBOX
30
660
180
678
PREY PARAMETERS
13
95.0
1

TEXTBOX
25
685
175
703
Energy gains
11
0.0
1

TEXTBOX
250
685
400
703
regrowth rates
11
0.0
1

TEXTBOX
542
685
692
703
individual weights
11
0.0
1

TEXTBOX
1325
35
1570
53
MAP SELECTION / EDITOR
14
15.0
1

BUTTON
170
15
242
60
go once
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

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
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
1
@#$#@#$#@
