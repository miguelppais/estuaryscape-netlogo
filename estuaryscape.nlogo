;;;;;;;;;;;;;;;;;;;;;;
;;                  ;;     Created by Miguel Pessanha Pais as a final project for the intro to ABM MOOC 2016
;;ESTUARYSCAPE MODEL;;                     by Bill Rand @ Complexity Explorer
;;                  ;;
;;;;;;;;;;;;;;;;;;;;;;                         Contact: mppais@fc.ul.pt

extensions [gis]

breed [fishes fish]

globals[
  the-map
  non-land-patches       ; an agentset of patches that excludes land patches, to avoid unnecessary calculations happening in land
  ; other globals are on the interface
]

fishes-own [
  energy                  ; current energy level, limited by energy-reserve-size
  species                 ; green or red species
  sex                     ; male, female or undecided (joking, just male or female really)
  reserve-size            ; maximum energy reserve size
  maintenance-cost        ; energy cost to maintain bodily functions (metabolism,respiration, osmotic regulation, etc)
  age                     ; age (in days)
  stage                   ; juvenile or adult
  age-at-maturity         ; age at which a fish becomes and adult (able to reproduce) (days)
  max-age                 ; maximum age for fish (instant death lies beyond this point)
  nr-gametes              ; nr of gametes produced by adults
  feeding-rate            ; max amount of prey grams per day
  reproduction-threshold  ; energy amount over which an adult fish can produce and release gametes
  ]

patches-own [
  worms
  bivalves
  plankton
  habitat ; canal or mudflat
  green-newcomers
  red-newcomers
  red.eggs ; red fish eggs, coded as a list with the length equal to "days-until-hatch". The first item is the amount of eggs released on the present day, the last item is eggs who have been here for "days-until-hatch" days and are ready to hatch.
  green.eggs ; green fish eggs, see the description above
  ]

; Model setup and schedule

to startup
  set map-file "map.asc"
  load-map
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
    pay-maintenance                    ; pay maintenance-costs or die!
    move-or-stay                     ; move or stay based on the scan decision
  ]
  fish-eat-prey                       ; fish eat prey, larger fish get to eat first
  egg-development                     ; eggs age advances
  hatch-eggs                          ; eggs that reach full development hatch
  fish-reproduction                   ; fish reproduce
  regrow-prey                         ; prey grows back
  tick
end


; SETUP PROCEDURES

to setup-fishes
  create-fishes initial-number-of-fishes [
    move-to-and-jitter one-of non-land-patches ; place fishes on a random patch that is not land and jitter
    set color one-of [red green]
    set sex one-of ["male" "female"]
    set shape "fish"
  ]

  ask fishes with [color = red] [                                  ; setup red fish attributes
    set species "red"
    set age-at-maturity age-at-maturity-red * 365                 ; convert age to days (ticks)
    set max-age max-age-red * 365
    set feeding-rate max-feeding-rate-red
    set reproduction-threshold reproduction-threshold-red
  ]

  ask fishes with [color = green] [                                 ; setup green fish attributes
    set species "green"
    set age-at-maturity age-at-maturity-green * 365                ; convert age to days (ticks)
    set max-age max-age-green * 365
    set feeding-rate max-feeding-rate-green
    set reproduction-threshold reproduction-threshold-green
  ]

  ask fishes [
    set reserve-size max-energy-reserve
    set age floor random-normal (max-age / 2) ((max-age / 2) * 0.3)     ; distribute ages with the mean as half the life expectancy and a CV of 30%
    if age < 0 [set age 0]                                        ; correct fish with negative age
    ifelse age >= age-at-maturity [set stage "adult"] [set stage "juvenile"]   ; assign life stages
    set size 0.3 + ((age / max-age) * 0.3)                        ; scale the size according to age
    scale-reserve-size
    scale-maintenance
    scale-feeding-rate
    set energy (0.7 * reserve-size) + (random-float 0.3 * reserve-size) ; initial energy varies randomly from 70 to 100% reserve size

  ]

end



; setup the environment

to load-map      ;observer procedure
  carefully [
    set the-map gis:load-dataset map-file
    gis:apply-raster the-map pcolor
    ask patches [
      if pcolor = 96 [set habitat "canal"]
      if pcolor = 37 [set habitat "mudflat"]
      if pcolor = green [set habitat "land"]
    ]
    ] [create-map-file]

  set non-land-patches patches with [habitat != "land"]
end

to setup-environment      ; observer procedure
  ask non-land-patches [
    set green.eggs n-values days-until-hatch [0]                    ; eggs are initialized as lists of length "days-until-hatch"
    set red.eggs n-values days-until-hatch [0]
  ]
  ask non-land-patches with [habitat = "mudflat"] [                 ; patches are populated with a random number of prey between half and total carrying capacity
    set worms random-between (floor max-worms-mudflat / 2) max-worms-mudflat
    set bivalves random-between (floor max-bivalves-mudflat / 2) max-bivalves-mudflat
    set plankton random-between (floor max-plankton-mudflat / 2) max-plankton-mudflat
  ]
  ask non-land-patches with [habitat = "canal"] [
    set worms random-between (floor max-worms-canal / 2) max-worms-canal
    set bivalves random-between (floor max-bivalves-canal / 2) max-bivalves-canal
    set plankton random-between (floor max-plankton-canal / 2) max-plankton-canal
  ]
end


; this startup procedure generates an example map and saves the map as a raster file in the model folder. This only happens if the file is not found.

to create-map-file   ; observer procedure

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

user-message "Welcome! The specified map file was not found or this is your first time here! The default map has been loaded and saved as a map.asc file in your model folder. This message will only appear again if you delete this file. If you are feeling creative, use the map editor to create maps and save them, but don't forget to give them a different name! Have fun exploring!"

end

;; FISH-RELATED PROCEDURES

to scale-reserve-size  ; fish procedure                                           ; reserve size starts at 10% max when age = 0 and increases until 100% at age-at-maturity
  set maintenance-cost (0.1 * reserve-size) + ((age / (age-at-maturity)) * (0.9 * reserve-size))
end

to scale-maintenance ; fish procedure                                                 ; maintenance cost starts at 10% max when age = 0 and increases until 100% at age-at-maturity
   set maintenance-cost (0.1 * max-maintenance-cost) + ((age / (age-at-maturity)) * (0.9 * max-maintenance-cost))
end

to scale-feeding-rate   ; fish procedure                                              ; feeding rate starts at 10% max when age = 0 and increases until 100% at age-at-maturity
  set feeding-rate (0.1 * feeding-rate) + ((age / (age-at-maturity)) * (0.9 * feeding-rate))
end

to pay-maintenance ; fish procedure
  set energy energy - maintenance-cost
  if energy <= 0 [die] ; fish die if they can't pay maintenance
end

to move-to-and-jitter [p] ; fish procedure                                      ; moves to a patch and jitters fish coordinates within patch for easier visualization
  let x [pxcor] of p
  let y [pycor] of p
  setxy (x + random-float-between -0.49 0.49) (y + random-float-between -0.49 0.49)
end


to grow ; fish procedure
  if age >= max-age [die]
  set age age + 1
  if age = age-at-maturity [set stage "adult"]                 ; puberty...
  set size 0.3 + ((age / max-age) * 0.3)                        ; scale the size according to age
  scale-reserve-size
  scale-maintenance
end

; fishes decide whether to stay or move based on the conditions of the current patch

to move-or-stay ; fish procedure

  ifelse energy < (maintenance-cost + small-movement-cost) [stay] [              ; if really low on energy, just don't move. Else, it depends on who you are and what you need.

  if (stage = "adult") [
    ifelse energy > reproduction-threshold [
    ifelse any? fishes-here with [sex != [sex] of myself and species = [species] of myself] [stay] [move]   ; if ready to reproduce, check for opposite sex and same species, leave if not found
  ] [
  scan-prey                                                                     ; if an adult, but not ready to reproduce, scan prey options
  ]
  ]

  if (age > plankton-eating-period and stage = "juvenile") [                                     ; if a juvenile has left plankton eating period, scan prey options
    scan-prey
  ]

  if (age <= plankton-eating-period) [                                                  ; if in the plankton eating period
    let required-energy reserve-size - energy
    let potentially-available-energy 0
    ifelse any? other fishes-here with [age <= plankton-eating-period] [
      set potentially-available-energy energy-gain-from-plankton * ((plankton * weight-per-plankton) - sum [feeding-rate] of other fishes-here with [age <= plankton-eating-period])  ; if there are other young juveniles here, check energy gain from available plankton grams if everyone ate their max.
      ifelse potentially-available-energy < required-energy [move] [stay]
      ] [
      set potentially-available-energy (plankton * plankton-value)                                                               ; if there are not any young juveniles here, just check if there is enough plankton for me
      ifelse potentially-available-energy < required-energy [move] [stay]
      ]
  ]
  ]
end

; fish evaluate the amount of energy they need and the available energy at the current patch, and wether larger fish will likely eat everything

to scan-prey   ; fish procedure
  let required-energy 0
  let worms-available-energy 0
  let bivalves-available-energy 0
  ifelse any? other fishes-here with [age > plankton-eating-period and size >= [size] of myself] [
    set required-energy reserve-size - energy
    set worms-available-energy energy-gain-from-worms * ((worms * weight-per-worm) - sum [feeding-rate] of other fishes-here with [age > plankton-eating-period and size >= [size] of myself])  ; if there are other larger fish here, check energy gain from available worms grams if everyone ate worms (exclude very young plankton eaters)
    set bivalves-available-energy energy-gain-from-bivalves * ((bivalves * weight-per-bivalve) - sum [feeding-rate] of other fishes-here with [age > plankton-eating-period and size >= [size] of myself])  ; if there are other fish here, check energy gain from available worms grams if everyone ate worms (exclude very young plankton eaters)
    ifelse (worms-available-energy < required-energy or bivalves-available-energy < required-energy) [move] [stay]
  ] [
  set required-energy reserve-size - energy
  set worms-available-energy (worms * worms-value)                                                               ; if there are not any other fish here, just check if there is enough food for me (exclude young plankton eaters)
  set bivalves-available-energy (bivalves * bivalves-value)
  ifelse (worms-available-energy < required-energy or bivalves-available-energy < required-energy) [move] [stay]
  ]

end

to move          ; fish procedure                         ; fish move to a neighboring patch, spending more energy in locomotion
  set energy energy - large-movement-cost
  move-to-and-jitter one-of neighbors with [habitat != "land"]
end

to stay          ; fish procedure                      ; fish just move within the patch, spending less energy
  set energy energy - small-movement-cost
end


; The extremely complex thought process of fish as they pick which prey to eat based on their needs.

to eat       ; fish procedure
  ifelse age <= plankton-eating-period [                                                                   ; if you are a young plankton eater
    if plankton = 0 [stop]                                                              ; if there's no plankton here, I'm not eating today
    let required-amount ceiling ((reserve-size - energy) / (energy-gain-from-plankton)) ; required amount (in grams)
    if required-amount > feeding-rate [set required-amount feeding-rate]                ; required amount is limited by feeding rate
    let available-amount (plankton * weight-per-plankton)                               ; available amount (in grams)
    let consumed-amount  min list required-amount available-amount       ; each fish consumes the minimum value among required and available
    ask patch-here [
      set plankton plankton - ceiling (consumed-amount / weight-per-plankton)            ; eat the number of plankton required
    ]
    set energy energy + ceiling (consumed-amount / weight-per-plankton) * plankton-value ; replenish energy

  ] [ ; else                                                                                ; if you can eat big prey
  if worms = 0 and bivalves = 0 [stop]                                                      ; if there are no big prey, I'm not eating today
  let required-amount-worms ceiling ((reserve-size - energy) / (energy-gain-from-worms)) ; required amount of worms (in grams)
  let required-amount-bivalves ceiling ((reserve-size - energy) / (energy-gain-from-bivalves))  ; required amount of bivalves (in grams)
  if required-amount-worms > feeding-rate [set required-amount-worms feeding-rate]             ; required amounts are limited by feeding rates
  if required-amount-bivalves > feeding-rate [set required-amount-bivalves feeding-rate]
  let available-amount-worms (worms * weight-per-worm)                               ; available amount (in grams)
  let available-amount-bivalves (bivalves * weight-per-bivalve)
  let chosen-prey "none"                                             ; create local variable
  let consumed-amount 0                                             ; create local variable
  if ((required-amount-worms - available-amount-worms <= 0) and (required-amount-bivalves - available-amount-bivalves <= 0)) [   ; if any prey can fill up energy, pick the one that can do it with less quantity
    ifelse required-amount-worms < required-amount-bivalves [
      set chosen-prey "worms"
      set consumed-amount required-amount-worms
      ] [
      set chosen-prey "bivalves"
      set consumed-amount required-amount-bivalves
      ]
  ]
  if ((required-amount-worms - available-amount-worms <= 0) and (required-amount-bivalves - available-amount-bivalves > 0)) [   ; if only worms can fill up energy, eat  worms
    set chosen-prey "worms"
    set consumed-amount required-amount-worms
  ]
  if ((required-amount-worms - available-amount-worms > 0) and (required-amount-bivalves - available-amount-bivalves <= 0)) [   ; if only bivalves can fill up energy, eat bivalves
    set chosen-prey "bivalves"
    set consumed-amount required-amount-bivalves
  ]
  if ((required-amount-worms - available-amount-worms > 0) and (required-amount-bivalves - available-amount-bivalves > 0)) [   ; if none of the prey can fill up energy, pick the one which can provide more energy that day and eat what's available
    ifelse (available-amount-worms * energy-gain-from-worms) > (available-amount-bivalves * energy-gain-from-bivalves) [
      set chosen-prey "worms"
      set consumed-amount available-amount-worms
      ] [
      set chosen-prey "bivalves"
      set consumed-amount available-amount-bivalves
      ]
  ]
  ask patch-here [
    ifelse chosen-prey = "worms" [set worms worms - ceiling (consumed-amount / weight-per-worm)   ; deplete worms or bivalves from the patch depending on chosen prey
    ] [
    set bivalves bivalves - ceiling (consumed-amount / weight-per-bivalve)
    ]
  ]
  ifelse chosen-prey = "worms" [set energy energy + ceiling (consumed-amount / weight-per-worm) * worms-value ; gain energy from worms or bivalves depending on chosen prey
  ] [
  set energy energy + ceiling (consumed-amount / weight-per-bivalve) * bivalves-value
  ]
  ] ; end ifelse
end

to fish-eat-prey  ; observer procedure
  ask fishes with [not any? other fishes-here] [eat]                          ; fish who are alone eat the most valuable prey if there is enough quantity

  ask non-land-patches with [count fishes-here > 1] [sort-out-competition]    ; when there are crowded patches, the patch handles prey distribution

end

to sort-out-competition ; patch procedure
  foreach sort-on [0 - size] fishes-here [ ?1 ->          ; fishes eat in descending order of size (proxy of age)
   ask ?1 [eat]
  ]
end


; If both sexes of adults ready for reproduction are present, they release gametes to the patch. Incubation is external, so it occurs on the patch, mixing up gametes from several males and females.

to fish-reproduction     ; observer procedure
  ask non-land-patches with [length (remove-duplicates [sex] of fishes-here with [species = "green" and stage = "adult" and energy > reproduction-threshold]) = 2] [  ; patches with both sexes of green adults fit for reproduction
    let green-reproductive-adults fishes-here with [species = "green" and stage = "adult" and energy > reproduction-threshold]
    ask green-reproductive-adults [
      set nr-gametes floor (energy - reproduction-threshold) / cost-per-gamete     ; the number of eggs procuced equals the surplus energy divided by the energetic cost per gamete
      set energy (energy - (nr-gametes * cost-per-gamete))                         ; energy of the gametes produced is removed from the fish
    ]
    let green-female-gametes sum [nr-gametes] of green-reproductive-adults with [sex = "female"]
    let green-male-gametes sum [nr-gametes] of green-reproductive-adults with [sex = "male"]
    set green.eggs replace-item 0 green.eggs ((min list green-female-gametes green-male-gametes) * (1 - (egg-mortality-green / 100))) ; the minimum number between female and male gametes is picked as the nr of eggs (two are needed). The other gametes are wasted.
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
    set red.eggs replace-item 0 red.eggs ((min list red-female-gametes red-male-gametes) * (1 - (egg-mortality-red / 100)))  ; the minimum number between female and male gametes is picked as the nr of eggs (two are needed). The other gametes are wasted.
    ask red-reproductive-adults [set nr-gametes 0]
  ]


end



;; PATCH-RELATED PROCEDURES



to egg-development             ; observer procedure
  ask non-land-patches [
    set green.eggs remove-item (days-until-hatch - 1) green.eggs                         ; the eggs list shifts one position to the right, the last item being the eggs ready to hatch on the current tick
    set red.eggs remove-item (days-until-hatch - 1) red.eggs

    set green.eggs fput 0 green.eggs
    set red.eggs fput 0 red.eggs
  ]
end

; eggs that have reached "days-until-hatch" are sent to a random number of mudflat patches between half the total area and the total mudflat area

to hatch-eggs                  ; observer procedure
  let mudflat-patches non-land-patches with [habitat = "mudflat"]
  ask non-land-patches with [last green.eggs > 0] [          ; hatch green eggs
  let nr-green-eggs last green.eggs
  set green.eggs replace-item (days-until-hatch - 1) green.eggs 0       ;eggs hatched, so they are removed from the patch variable
  let number-patches 0
  ifelse nr-green-eggs > count mudflat-patches [
    set number-patches random-between (floor count mudflat-patches / 2) (floor count mudflat-patches)
    ] [
    set number-patches random-between 1 nr-green-eggs             ; if small amount of eggs, max patches is nr of eggs (1 egg per patch)
    ]
  ask n-of number-patches mudflat-patches [
    set green-newcomers green-newcomers + nr-green-eggs / number-patches
    ]
  ]
  ask non-land-patches with [last red.eggs > 0] [          ; hatch red eggs
  let nr-red-eggs last red.eggs
  set red.eggs replace-item (days-until-hatch - 1) red.eggs 0       ;eggs hatched, so they are removed from the patch variable
  let number-patches 0
  ifelse nr-red-eggs > count mudflat-patches [
    set number-patches random-between (floor count mudflat-patches / 2) (floor count mudflat-patches)
    ] [
    set number-patches random-between 1 nr-red-eggs
    ]
  ask n-of number-patches mudflat-patches [
    set red-newcomers red-newcomers + nr-red-eggs / number-patches
    ]
  ]

  ask mudflat-patches with [green-newcomers > 0 and red-newcomers > 0] [    ; patches with both species trying to settle. Each species scans 1/4 of the carrying capacity
    let carrying-capacity floor (plankton * weight-per-plankton) / (max-feeding-rate-green * 0.1)  ; 10% feeding rate at age 0
    let settled-greens min list (floor (carrying-capacity / 4)) green-newcomers   ; number of settlers limited by carrying capacity
    let settled-reds min list (floor (carrying-capacity / 4)) red-newcomers
    settle-greens settled-greens
    settle-reds settled-reds
    set red-newcomers 0
    set green-newcomers 0
  ]

  ask mudflat-patches with [green-newcomers = 0 and red-newcomers > 0] [  ; patches with only red settlers, scan 1/2 of the carrying capacity
    let carrying-capacity (plankton * weight-per-plankton) / (max-feeding-rate-red * 0.1)
    let settled-reds min list (carrying-capacity / 2) red-newcomers
    settle-reds settled-reds
    set red-newcomers 0
  ]

  ask mudflat-patches with [green-newcomers > 0 and red-newcomers = 0] [   ; patches with only green settlers, scan 1/2 of the carrying capacity
    let carrying-capacity (plankton * weight-per-plankton) / (max-feeding-rate-green * 0.1)
    let settled-greens min list (carrying-capacity / 2) green-newcomers
    settle-greens settled-greens
    set green-newcomers 0
  ]

end

to settle-reds [nr] ; patch procedure
  sprout-fishes nr [
    set reserve-size max-energy-reserve
    set sex one-of ["male" "female"]
    set shape "fish"
    set species "red"
    set color red
    set age 0
    set size 0.3
    set age-at-maturity age-at-maturity-red * 365                ; convert age to days (ticks)
    set max-age max-age-red * 365
    set feeding-rate max-feeding-rate-red
    set reproduction-threshold reproduction-threshold-red
    scale-reserve-size
    scale-maintenance
    scale-feeding-rate
    set energy (0.7 * reserve-size) + (random-float 0.3 * reserve-size) ; initial energy varies randomly from 70 to 100% reserve size
    move-to-and-jitter patch-here ; jitter in the current patch
  ]
end

to settle-greens [nr]   ; patch procedure
  sprout-fishes nr [
    set reserve-size max-energy-reserve
    set sex one-of ["male" "female"]
    set shape "fish"
    set species "green"
    set color green
    set age 0
    set size 0.3
    set age-at-maturity age-at-maturity-green * 365                ; convert age to days (ticks)
    set max-age max-age-green * 365
    set feeding-rate max-feeding-rate-green
    set reproduction-threshold reproduction-threshold-green
    scale-reserve-size
    scale-maintenance
    scale-feeding-rate
    set energy (0.7 * reserve-size) + (random-float 0.3 * reserve-size) ; initial energy varies randomly from 70 to 100% reserve size
    move-to-and-jitter patch-here   ; jitter in the current patch
    ]
end

to regrow-prey              ; obsever procedure
  ask non-land-patches [
    if worms < 0 [set worms 0]
    if bivalves < 0 [set bivalves 0]
    if plankton < 0 [set plankton 0]
    set worms worms + worms-regrowth-rate
    set bivalves bivalves + bivalves-regrowth-rate
    set plankton plankton + plankton-regrowth-rate

    ; limit the amount of prey to the carrying capacity of the habitat

    if habitat = "mudflat" [
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

;; PREY REPORTERS

to-report worms-value
report precision (energy-gain-from-worms * weight-per-worm) 3
end

to-report bivalves-value
report precision (energy-gain-from-bivalves * weight-per-bivalve) 3
end

to-report plankton-value
report precision (energy-gain-from-plankton * weight-per-plankton) 3
end

; FISH REPORTERS (these were not fully implemented, but are based on real data from Solea solea and can be used to estimate parameters.)

to-report get-length [t]
  report 38 * (1 - exp(-0.43 * ((t / 365) + 0.1))) ; cm, t in days
end

to-report get-weight [L]      ; g, L in cm
  report 0.0062 * (L ^ 3.13)
end

to-report get-feeding-rate [t]  ; g / day, t in days
  let L get-length t
  let w get-weight L
  report 0.092 * w
end


; PLOTTING AND OUTPUTS

; plot and monitor code is in the plots and monitors on the interface tap


; MAP EDITOR

to draw-canals
  if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ask patch mouse-xcor mouse-ycor
        [ set pcolor 96
          set habitat "canal"
          display ]
    ]
end


to draw-mudflats
  if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ask patch mouse-xcor mouse-ycor
        [ set pcolor 37
          set habitat "mudflat"
          display ]
    ]
end

to erase-map
   if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ask patch mouse-xcor mouse-ycor
        [ set pcolor black
          set habitat ""
          display ]
    ]
end

to fill-land
  ask patches with [pcolor = black] [
   set pcolor green
   set habitat "land"
  ]
end


;; USEFUL REPORTERS

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
763
519
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
Days
30.0

BUTTON
15
10
78
55
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
10
167
55
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
180
240
213
initial-number-of-fishes
initial-number-of-fishes
10
500
150.0
5
1
NIL
HORIZONTAL

SLIDER
245
790
535
823
worms-regrowth-rate
worms-regrowth-rate
0
500
5.0
5
1
/ day
HORIZONTAL

SLIDER
20
790
245
823
energy-gain-from-worms
energy-gain-from-worms
0
100
7.0
1
1
per g
HORIZONTAL

SLIDER
1190
795
1380
828
large-movement-cost
large-movement-cost
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
245
835
535
868
bivalves-regrowth-rate
bivalves-regrowth-rate
0
500
5.0
5
1
/ day
HORIZONTAL

SLIDER
245
880
535
913
plankton-regrowth-rate
plankton-regrowth-rate
0
20000
200.0
100
1
/ day
HORIZONTAL

SLIDER
20
835
245
868
energy-gain-from-bivalves
energy-gain-from-bivalves
0
100
10.0
1
1
per g
HORIZONTAL

SLIDER
20
880
245
913
energy-gain-from-plankton
energy-gain-from-plankton
0
100
6.0
1
1
per g
HORIZONTAL

SLIDER
1085
90
1275
123
age-at-maturity-red
age-at-maturity-red
1
10
2.0
1
1
years
HORIZONTAL

SLIDER
1290
90
1480
123
age-at-maturity-green
age-at-maturity-green
1
10
2.0
1
1
years
HORIZONTAL

SLIDER
1085
125
1275
158
max-age-red
max-age-red
1
10
4.0
1
1
years
HORIZONTAL

SLIDER
1290
125
1480
158
max-age-green
max-age-green
1
10
4.0
1
1
years
HORIZONTAL

SLIDER
1085
160
1275
193
max-feeding-rate-red
max-feeding-rate-red
1
50
35.0
1
1
g/day
HORIZONTAL

SLIDER
1290
160
1480
193
max-feeding-rate-green
max-feeding-rate-green
1
50
35.0
1
1
g/day
HORIZONTAL

SLIDER
1190
725
1380
758
max-maintenance-cost
max-maintenance-cost
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
1190
760
1380
793
small-movement-cost
small-movement-cost
0
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
1085
195
1275
228
reproduction-threshold-red
reproduction-threshold-red
0
1000
800.0
10
1
NIL
HORIZONTAL

SLIDER
1290
195
1480
228
reproduction-threshold-green
reproduction-threshold-green
0
1000
800.0
10
1
NIL
HORIZONTAL

SLIDER
1190
830
1380
863
cost-per-gamete
cost-per-gamete
0.01
1
0.4
0.01
1
NIL
HORIZONTAL

SLIDER
1190
865
1380
898
days-until-hatch
days-until-hatch
1
30
10.0
1
1
NIL
HORIZONTAL

SLIDER
1085
230
1275
263
egg-mortality-red
egg-mortality-red
0
100
80.0
5
1
%
HORIZONTAL

SLIDER
1290
230
1480
263
egg-mortality-green
egg-mortality-green
0
100
80.0
5
1
%
HORIZONTAL

SLIDER
1190
690
1380
723
max-energy-reserve
max-energy-reserve
10
1000
1000.0
10
1
NIL
HORIZONTAL

SLIDER
535
790
720
823
weight-per-worm
weight-per-worm
0.01
1
0.4
0.01
1
g
HORIZONTAL

SLIDER
535
835
720
868
weight-per-bivalve
weight-per-bivalve
0.01
1
0.5
0.01
1
g
HORIZONTAL

SLIDER
535
880
720
913
weight-per-plankton
weight-per-plankton
0.001
0.01
0.01
0.001
1
g
HORIZONTAL

SLIDER
812
790
984
823
max-worms-mudflat
max-worms-mudflat
0
500
80.0
10
1
NIL
HORIZONTAL

SLIDER
812
835
984
868
max-bivalves-mudflat
max-bivalves-mudflat
0
500
30.0
10
1
NIL
HORIZONTAL

SLIDER
812
880
984
913
max-plankton-mudflat
max-plankton-mudflat
0
10000
4100.0
100
1
NIL
HORIZONTAL

SLIDER
982
790
1154
823
max-worms-canal
max-worms-canal
0
500
30.0
10
1
NIL
HORIZONTAL

SLIDER
982
835
1154
868
max-bivalves-canal
max-bivalves-canal
0
500
80.0
10
1
NIL
HORIZONTAL

SLIDER
982
880
1154
913
max-plankton-canal
max-plankton-canal
0
10000
4100.0
100
1
NIL
HORIZONTAL

BUTTON
405
645
525
678
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
525
645
645
678
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
405
695
765
728
Fill black patches with land
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
645
645
765
678
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
585
610
765
643
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
405
610
585
643
Clear map
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
15
110
240
170
map-file
map.asc
1
0
String

PLOT
15
270
240
420
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
420
240
540
Red age distribution
Age (years)
Nr of fish
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Red" 1.0 1 -2674135 true "" "histogram [floor (age / 365)] of fishes with [species = \"red\" and age > 365]"

PLOT
15
540
240
660
Green age distribution
Age (years)
Nr. of fish
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Green" 1.0 1 -10899396 true "" "histogram [floor (age / 365)] of fishes with [species = \"green\"]"

BUTTON
1290
55
1480
88
Same as red
set age-at-maturity-green age-at-maturity-red\nset max-age-green max-age-red\nset max-feeding-rate-green max-feeding-rate-red\nset reproduction-threshold-green reproduction-threshold-red\nset egg-mortality-green egg-mortality-red
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
790
815
835
worms value
worms-value
2
1
11

MONITOR
720
835
815
880
bivalves value
bivalves-value
17
1
11

MONITOR
720
880
815
925
plankton value
plankton-value
17
1
11

TEXTBOX
717
770
827
788
Energy per prey item
11
0.0
1

TEXTBOX
932
770
1082
788
CARRYING CAPACITY
11
0.0
1

TEXTBOX
30
745
180
763
PREY PARAMETERS
13
95.0
1

TEXTBOX
25
770
175
788
Energy gains
11
0.0
1

TEXTBOX
250
770
400
788
population growth rates
11
0.0
1

TEXTBOX
542
770
692
788
individual weights
11
0.0
1

TEXTBOX
315
650
395
668
MAP EDITOR
14
15.0
1

BUTTON
170
10
242
55
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

MONITOR
255
545
325
590
% mudflat
precision ((count patches with [habitat = \"mudflat\"] / count patches with [habitat != \"land\"]) * 100) 1
17
1
11

MONITOR
330
545
400
590
% canal
precision ((count patches with [habitat = \"canal\"] / count patches with [habitat != \"land\"]) * 100) 1
17
1
11

TEXTBOX
270
590
310
608
brown
15
35.0
1

TEXTBOX
350
590
385
608
blue
15
96.0
1

TEXTBOX
410
680
765
700
Pick a tool, draw with the mouse on the map. Activate only one at a time!
11
0.0
1

MONITOR
15
220
120
265
red population
count fishes with [species = \"red\"]
17
1
11

MONITOR
120
220
240
265
Green population
count fishes with [species = \"green\"]
17
1
11

MONITOR
1085
275
1275
320
Max egg production
floor ((1 - (egg-mortality-red / 100)) * (max-energy-reserve - reproduction-threshold-red) / cost-per-gamete)
17
1
11

MONITOR
1290
275
1480
320
Max egg production
floor ((1 - (egg-mortality-green / 100)) * (max-energy-reserve - reproduction-threshold-green) / cost-per-gamete)
17
1
11

BUTTON
525
545
645
578
display plankton
ask patches with [habitat = \"mudflat\"] [\nset pcolor scale-color 37 plankton 0 (max list max-plankton-mudflat max-plankton-canal)\n]\nask patches with [habitat = \"canal\"] [\nset pcolor scale-color 96 plankton 0 (max list max-plankton-mudflat max-plankton-canal)\n]\ndisplay
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
405
545
525
578
display worms
ask patches with [habitat = \"mudflat\"] [\nset pcolor scale-color 37 worms (max list max-worms-mudflat max-worms-canal) 0\n]\nask patches with [habitat = \"canal\"] [\nset pcolor scale-color 96 worms (max list max-worms-mudflat max-worms-canal) 0\n]\ndisplay
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
645
545
765
578
display bivalves
ask patches with [habitat = \"mudflat\"] [\nset pcolor scale-color 37 bivalves 0 (max list max-bivalves-mudflat max-bivalves-canal)\n]\nask patches with [habitat = \"canal\"] [\nset pcolor scale-color 96 bivalves 0 (max list max-bivalves-mudflat max-bivalves-canal)\n]\ndisplay
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
415
580
530
598
Darker = more prey\n
11
0.0
1

TEXTBOX
1190
10
1370
28
FISH SPECIES PARAMETERS
14
0.0
1

TEXTBOX
1165
35
1200
53
RED
15
15.0
1

TEXTBOX
1360
35
1420
53
GREEN
15
55.0
1

TEXTBOX
1250
670
1345
688
COMMON
15
0.0
1

MONITOR
1085
320
1275
365
Max worms / day
floor (max-feeding-rate-red / weight-per-worm)
17
1
11

MONITOR
1290
320
1480
365
Max worms / day
floor (max-feeding-rate-green / weight-per-worm)
17
1
11

MONITOR
1085
365
1275
410
Max bivalves / day
floor (max-feeding-rate-red / weight-per-bivalve)
17
1
11

MONITOR
1290
365
1480
410
Max bivalves / day
floor (max-feeding-rate-green / weight-per-bivalve)
17
1
11

MONITOR
1085
410
1275
455
Max plankton / day
floor (((0.1 * max-feeding-rate-red) + ((365 / (age-at-maturity-red * 365)) * (0.9 * max-feeding-rate-red))) / weight-per-plankton)
17
1
11

MONITOR
1290
410
1480
455
Max plankton / day
floor (((0.1 * max-feeding-rate-green) + ((365 / (age-at-maturity-green * 365)) * (0.9 * max-feeding-rate-green))) / weight-per-plankton)
17
1
11

TEXTBOX
1485
415
1565
445
for a 1 year old larvae
11
0.0
1

TEXTBOX
525
580
695
616
SWITCH ONLY ONE AT A TIME!!\nEPILEPSY WARNING!!!
11
15.0
1

MONITOR
1085
595
1275
640
Feeding rate at age 1
(0.1 * max-feeding-rate-red) + ((365 / (age-at-maturity-red * 365)) * (0.9 * max-feeding-rate-red))
17
1
11

MONITOR
1290
595
1480
640
Feeding rate at age 1
(0.1 * max-feeding-rate-green) + ((365 / (age-at-maturity-green * 365)) * (0.9 * max-feeding-rate-green))
17
1
11

MONITOR
1085
455
1275
500
Max energy from worms
floor (max-feeding-rate-red / weight-per-worm) * worms-value
17
1
11

MONITOR
1290
455
1480
500
Max energy from worms
floor (max-feeding-rate-green / weight-per-worm) * worms-value
17
1
11

MONITOR
1085
500
1275
545
Max energy from bivalves
floor (max-feeding-rate-red / weight-per-bivalve) * bivalves-value
17
1
11

MONITOR
1290
500
1480
545
Max energy from bivalves
floor (max-feeding-rate-green / weight-per-bivalve) * bivalves-value
17
1
11

MONITOR
1085
545
1275
590
Max energy from plankton
ceiling (((0.1 * max-feeding-rate-red) + ((365 / (age-at-maturity-red * 365)) * (0.9 * max-feeding-rate-red))) / weight-per-plankton) * plankton-value
17
1
11

MONITOR
1290
545
1480
590
Max energy from plankton
ceiling (((0.1 * max-feeding-rate-green) + ((365 / (age-at-maturity-green * 365)) * (0.9 * max-feeding-rate-green))) / weight-per-plankton) * plankton-value
17
1
11

BUTTON
1085
55
1275
88
Same as green
set age-at-maturity-red age-at-maturity-green\nset max-age-red max-age-green\nset max-feeding-rate-red max-feeding-rate-green\nset reproduction-threshold-red reproduction-threshold-green\nset egg-mortality-red egg-mortality-green
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
1485
550
1565
580
for a 1 year old larvae
11
0.0
1

TEXTBOX
1485
210
1530
228
energy
11
0.0
1

PLOT
775
40
1070
220
Worms
days
Avg. nr worms
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"mudflats" 1.0 0 -3889007 true "" "plot (mean [worms] of non-land-patches with [habitat = \"mudflat\"])"
"canals" 1.0 0 -11033397 true "" "plot (mean [worms] of non-land-patches with [habitat = \"canal\"])"

PLOT
775
220
1070
400
Bivalves
days
Avg. nr bivalves
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"mudflats" 1.0 0 -3889007 true "" "plot (mean [bivalves] of non-land-patches with [habitat = \"mudflat\"])"
"canals" 1.0 0 -11033397 true "" "plot (mean [bivalves] of non-land-patches with [habitat = \"canal\"])"

PLOT
775
400
1070
580
Plankton
days
Avg. nr plankton
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"mudflats" 1.0 0 -3889007 true "" "plot (mean [plankton] of non-land-patches with [habitat = \"mudflat\"])"
"canals" 1.0 0 -11033397 true "" "plot (mean [plankton] of non-land-patches with [habitat = \"canal\"])"

TEXTBOX
875
15
965
33
PREY DENSITIES
11
0.0
1

TEXTBOX
1485
615
1525
633
g / day
11
0.0
1

SLIDER
1190
900
1380
933
plankton-eating-period
plankton-eating-period
0
365
180.0
5
1
days
HORIZONTAL

MONITOR
170
60
240
105
Year
floor (ticks / 365)
17
1
11

BUTTON
15
60
165
105
Set defaults
set map-file \"map.asc\"\nset initial-number-of-fishes 150\n\nset age-at-maturity-red 2\nset max-age-red 4\nset max-feeding-rate-red 35\nset reproduction-threshold-red 800\nset egg-mortality-red 80\n\nset age-at-maturity-green 2\nset max-age-green 4\nset max-feeding-rate-green 35\nset reproduction-threshold-green 800\nset egg-mortality-green 80\n\nset max-energy-reserve 1000\nset max-maintenance-cost 50\nset small-movement-cost 25\nset large-movement-cost 100\nset cost-per-gamete 0.4\nset days-until-hatch 10\nset plankton-eating-period 180\n\nset energy-gain-from-worms 7\nset worms-regrowth-rate 5\nset weight-per-worm 0.4\nset max-worms-mudflat 100\nset max-worms-canal 50\n\n\nset energy-gain-from-bivalves 10\nset bivalves-regrowth-rate 5\nset weight-per-bivalve 0.5\nset max-bivalves-mudflat 50\nset max-bivalves-canal 200\n\nset energy-gain-from-plankton 6\nset plankton-regrowth-rate 600\nset weight-per-plankton 0.01\nset max-plankton-mudflat 6600\nset max-plankton-canal 6600
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
## PURPOSE

This model attempts to simulate spatial interaction of 2 flatfish and 3 prey types in an estuary, featuring two different habitats, simple prey population dynamics, reproduction and competition. The model has simplified bioenergetics governing the state of each agent.

Lots of monitors help parameterise, but there are a lot of parameters! Try to see how many days your species can survive!

I am aware the model still has bugs here and there, this was done in 3 days, so not much time to debug... but I will be improving the code in my spare time.

## BACKGROUND

The common sole (Solea solea) and the Senegalese sole (Solea senegalensis) have come to share the same habitats, as climate change allows the latter species to move further North and overlap the habitat of the common sole. These very similar species now have to survive the fierce competition for similar resources. On the first year, they mostly eat zooplankton in the water column, but then they feed on both worms (polychaetes such as Hediste diversicolor) and bivalves (such as Scrobicularia plana).


## AGENT TYPES

The only moving agents are 2 fish species acting as competing predators. Three prey types are mostly fixed to a patch, varying only in their population densities. These are worms, bivalves and zooplankton.

## AGENT ATTRIBUTES

Both fish species have similar properties, which can be set equally or differently:

-	age-at-maturity: age at which a fish becomes an adult and is fit for reproduction
-	max age: maximum age
-	maximum feeding rate: maximum total size of prey a fish can eat in a day
-	energy reserve size: the size of the energy reserve, measured in arbitrary energy units, which limits feeding rates
-	maintenance cost: energy required to support life
-	small-movement cost: energy cost of staying in the same patch
-	large-movement cost: energy cost of moving to another patch
-	reproduction threshold: surplus energy level at which an adult fish becomes fit to produce gametes and starts to seek females
-	cost-per-gamete: energy cost of producing one gamete. This is used to calculate the number of eggs to generate.
-	Days until hatch: days from egg fecundation to hatch.
-	Egg mortality: fraction of eggs that die during the days it takes to hatch
-       Plankton eating period: amount of days post-settlement during which the fish only eats plankton.

Fish state variables include:

-	coordinates of their current patch
-	sex
-	an energy reserve compartment that stores energy assimilated from consumed prey, minus the maintenance costs
-	age (days)
-	life stage: juvenile or adult

All three prey types have similar fixed properties, but they can be different between types:

-	weight per prey: this impacts feeding rate, because larger prey occupy more volume in a stomach.
-	energy gain from prey: this is the amount of energy contained in 1 gram of prey, minus the energy required to eat it (chase, chew, filter…).
-       Growth rate, as in a fixed number of new individuals per day.
-	Carrying capacity in mudflats: maximum number of prey in mudflats
-	Carrying capacity in canals: maximum number of prey of this type in canals



## ENVIRONMENT

The environment is a spatially explicit depiction of a generic estuary with patches representing 2 habitats, mudflats and sandy canals. A third patch color is used to represent land, where nothing happens.

A patch represents 4 square meters. Each habitat can better support different types of prey. By default, worms prefer mudflats, bivalves prefer the canals and free-swimming plankton have no preference. Depth and water currents are ignored.

## AGENT BEHAVIOUR

Fish move by examining surrounding patches and deciding to stay or move to another patch based on the competition existing on the current patch, potential energy gains, current energy levels and whether or not they are ready to reproduce. Although there is a grid movement, fish are "jittered" for better visualisation (to avoid all fish in a patch being overlapped).

While on a patch, fish eat prey based on the energy requirements and feeding rate. Because fish can only pick one prey type per day, prey choice involves a decision process based on the potential energy gains.

Adults with enough energy reproduce if an adult of the opposite sex with enough energy to do so is present. Surviving fish eggs will remain in the patch of origin for the required time. Once they hatch, juveniles are randomly distributed across mudflat patches (less water flow, more protection) across the map. If they can eat given the current competition in the patch, they will be added as fish agents, if not the settlement is not successful and larvae die.
Prey grow with a pre-defined fixed rate, limited by carrying capacities.


## MODEL SCHEDULE

At the beggining, the map is loaded and fish are placed randomly on non-land patches, species and sexes are chosen randomly and ages are distributed normally around the middle of life expectancy.

Each model cycle represents one day, and events occur in this order:

- fish die if too old
- fish increase age, juveniles change to adults if they reach maturity, max energy, feeding rate and maintenance costs are proportional to age, until they reach the maximum at maturity.
- fish pay maintenance-costs or die!
- fish move or stay by scanning the environment
- fish eat-prey, larger fish get to eat first
- eggs age advances
- eggs that reach full development hatch
- fish reproduce
- prey grows back



## INPUTS AND OUTPUTS

Inputs

The initial number of fish from each breed, the percentage cover of each habitat type and all the parameters described for fish and prey.

Outputs

The population of each fish species, the number of days/years until population collapses, the spatial distribution of species and sizes.

Ultimately, it serves to attempt if two competing predators can find a way to survive and avoid the heavy costs of competition, even if the preferences for a certain habitat or prey are not specifically stated.

## WHAT TO DO

The mode has a lot of parameters, but it is still a very simplistic representation, so it can be hard to parameterise! Experimenting with species attributes and prey availabilities can lead to catastrophic outcomes very easily. Try to see how many days the populations can last. Try to give advantages to a species, such as faster maturity or more fecundity.

There is a map editor so you can draw your own estuary using the mouse! And then save the map as an .asc file to use later! See how the fish do in your estuary.

## REFERENCES

Cabral, H. N., Costa, M. J. (1999) Differential use of nursery areas within the Tagus estuary by sympatric soles, Solea solea and Solea senegalensis. Environmental Biology of Fishes 56, 389–397.

Froese, R., Pauly, D. (Eds.) (2016) FishBase. World Wide Web electronic publication. www.fishbase.org, ( 06/2016 ).

Lagardère, J.P. (1987) Feeding ecology and daily food consumption of common sole, Solea vulgaris Quensel, juveniles on the French Atlantic coast. Journal of Fish Biology 30, 91-104.

Vinagre, C., Cabral, H. N. (2008) Prey consumption by the juvenile soles, Solea solea and Solea senegalensis, in the Tagus estuary, Portugal. Estuarine, Coastal and Shelf Science 78, 45–50.

## COPYRIGHT AND LICENSE

Copyright 2017 Miguel P. Pais

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
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
NetLogo 6.0.2
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
