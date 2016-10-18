breed [fishes fish]
breed [predators predator]
breed [boats boat]
breed [detritus detritu]

turtles-own [ age  flockmates  nearest-neighbor energy]
patches-own [plankton polution ]
globals [ timenum]

to draw-island              ;; draw island
  if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ;; mouse-xcor and mouse-ycor report the position of the mouse --
      ;; note that they report the precise position of the mouse,
      ;; so you might get a decimal number like 12.3, but "patch"
      ;; automatically rounds to the nearest patch
      ask patch mouse-xcor mouse-ycor
        [ set pcolor red ]
    ]
end

to draw-source        ;;draw the source of reproduce
  if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ;; mouse-xcor and mouse-ycor report the position of the mouse --
      ;; note that they report the precise position of the mouse,
      ;; so you might get a decimal number like 12.3, but "patch"
      ;; automatically rounds to the nearest patch
      ask patch mouse-xcor mouse-ycor
        [ set pcolor pink ]
    ]
end


to draw-polution      ;; draw the pollution area
  if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ;; mouse-xcor and mouse-ycor report the position of the mouse --
      ;; note that they report the precise position of the mouse,
      ;; so you might get a decimal number like 12.3, but "patch"
      ;; automatically rounds to the nearest patch
      ask patch mouse-xcor mouse-ycor
        [ set pcolor grey ]
    ]
end

to setup
  clear-all
  ask patches  [                 ;;set up the planktons
    set pcolor blue
    set plankton random sea-regrow-time
    set pcolor one-of [green blue]
  ]
end

to create
  
  create-fishes number-of-fish [           ;;create certain numbers of forage fishes
    setxy random-xcor random-ycor
    set color red
    set shape "fish"  
    set age random 3
    set energy random random (2 * fish-gain-from-food)
    let x 0
    let y 0
    ask one-of patches with [pcolor != red]
    [
      set x pxcor
      set y pycor
    ]
    setxy x y
  ]
  
  

  
  create-predators number-of-predator [          ;;create certain numbers of predators
    setxy random-xcor random-ycor 
    set color yellow
    set shape "shark"
    set age random 5
    set energy random  (2 * predator-gain-from-food)
    set size 1.5 ;; increase their size so they are a little easier to see
    let x 0
    let y 0
    ask one-of patches with [pcolor != red]
    [
      set x pxcor
      set y pycor
    ]
    setxy x y
  ]
  if human-involoved?                       ;;if human being involved, create certain numbers of boats
  [ create-boats boats-number [  
    let x 0
    let y 0
    ask one-of patches with [pcolor != red]
    [
      set x pxcor
      set y pycor
    ]
    setxy x y
    set color white
    set shape "boat"  
    set size 2
  ]]
  
  reset-ticks
end




to go
 
  if not any? turtles [  
    stop
  ]
  
  ask fishes [
    ifelse flock? [                     ;; check if the forage fishes would go in the pattern as a flock
      flock
      avoid                          ;;forage fishes would escape if there is any predators around
     ; move
      ; fd 1
      ;   set age age + 1
      set energy energy - 1
      
    ]
    [ avoid
      
      ;move
      
      ; set age age + 1
      set energy energy - 1
    ]
    eat-plankton         ;;eat food and gain energy
    check-fish-dead       ;;check if the forage is dead or not
    
    fish-reproduce        ;;fish reproduce 
    
  ]
  

  
  
  ask predators [                  ;; ask predators to eat forage fishes and gain energy
    
    
    eat-fish
    
    
    set energy energy - 1
    check-if-dead
    set age age + 1
    predator-reproduce          ;;predator reproduce
  ]
  
  
  if human-involoved?
  [
    ask boats [
      move
      
      fishing           ;;human go fishing
    ]
  ]
  
  regrow-plankton        ;; regrow the plankton
  
  
  tick  
  my-update-plots
  
 
  
end


to flock  ;; turtle procedure
  find-flockmates
  if any? flockmates
    [ find-nearest-neighbor
      ifelse distance nearest-neighbor < 0.75
        [ separate ]
        [ align
          cohere ] ]
end

to find-flockmates  ;; turtle procedure
  set flockmates other turtles in-radius 3
end

to find-nearest-neighbor ;; turtle procedure
  set nearest-neighbor min-one-of flockmates [distance myself]
end

to separate  ;; turtle procedure
  turn-away ([heading] of nearest-neighbor) 3.50
end

to align  ;; turtle procedure
  turn-towards average-flockmate-heading 5
end

to cohere  ;; turtle procedure
  turn-towards average-heading-towards-flockmates 5.75
end

to turn-towards [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings heading new-heading) max-turn
end

to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0
      [ rt max-turn ]
      [ lt max-turn ] ]
    [ rt turn ]
end

to-report average-flockmate-heading  ;; turtle procedure
                                     ;; We can't just average the heading variables here.
                                     ;; For example, the average of 1 and 359 should be 0,
                                     ;; not 180.  So we have to use trigonometry.
  let x-component sum [dx] of flockmates
  let y-component sum [dy] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

to-report average-heading-towards-flockmates  ;; turtle procedure
                                              ;; "towards myself" gives us the heading from the other turtle
                                              ;; to me, but we want the heading from me to the other turtle,
                                              ;; so we add 180
  let x-component mean [sin (towards myself + 180)] of flockmates
  let y-component mean [cos (towards myself + 180)] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

to avoid ;; android procedure
  let candidates patches in-radius 1 with [ not any? predators ]        ;;if there is any predators around
  ifelse any? candidates
    [ face one-of candidates ]
    [ 
      let wall? false                              ;; check if there are walls ahead
      ask patch-ahead 1[
        if(pcolor = red)
        [
          set wall? true
        ]
      ] 
      ifelse (wall?)
      [
        rt random 360                              ;;if there are walls between walls between predators and fishes, random move
        move
      ]
      
      [ rt (random 3) * 90 
        
        ask patch-ahead 1[                 ;;else random pick a direction and escape
          if(pcolor = red)
          [
            set wall? true
          ]
        ] 
        ifelse (wall?)                       
        [
          avoid
          
        ]
        [forward 1  ]]]                  ;;if there are no predators around, move.
end

to chase                    ;;let predators chase after forage fishes for food
  ifelse any? fishes in-radius 2
    [ let candidates one-of fishes in-radius 2
      let wall? false                 ;;if there are forage fishes nearby
      ask patch-ahead 1[
        if(pcolor = red)
        [
          set wall? true                ;;check if there are walls between them
        ]
      ] 
      ifelse (wall?)
      [
        rt random 360       ;;if there are walls, random move
        move
      ]
      
      [
        face candidates           ;;if there are no walls, face the forage fish and move
        set energy energy - 1
        fd 1
      ]   
      
    ]
  
    [ if random 100 < predator-fight-percent          ;;if there are no forage fishes around, they might fight for their space
      [fight ] ]
  
end


to polution-on
;  ifelse ticks != nobody
 ; [set timenum ticks]
  ;[set timenum 0]
  set timenum ticks
  let polution-factor random 10
  ask patches with [pcolor = grey]
  [ set polution polution-factor
    ]
  
end

to self-restore                         ;;self restore the pollution emitted into the ocean
  clean
  tick
end
  


to clean                             ;;check if it has passed enough time to let ocean clean the pollution
  let now ticks
  if now = timenum + 3000
  [
    ask patches with [pcolor = grey]
    [set pcolor blue]]
end






to fight                                  ;; predators fight each other when there are not enough food around for their place
  ifelse any? predators in-radius 1
  
  [let candidates one-of predators in-radius 1  
    set energy energy - 4
    face candidates
    let walls patches in-radius 1 with [pcolor = red]
    ifelse any? walls                  
    [
      move]
    [forward 1  ]
    ask candidates [ die ]                  ;;one of the predators would die in this fight and the other one would loose a lot of energy also
    
  ]
  [ move
    set energy energy - 2]
end



to eat-plankton                         ;;forage fishes eat plankton
  if ( pcolor = green) [
    set pcolor blue         
    set energy energy + fish-gain-from-food
  ] 
end

to eat-fish                           ;;predators eat forage fishes
  ifelse any? fishes in-radius 1 [ 
    ask fishes in-radius 1 [     
      die
    ]
    set energy energy + predator-gain-from-food
  ]
  
  [ 
    if chase?                    ;;if there are no food around, look further and chase
    [chase]]
end

to fishing                       ;;human go fishing
  if random 100 < 70
    [
      ifelse prefer-big? [             ;;if human are prefer fishing the predators, they would catch one predator rather than all the nearby fishes
        ifelse any? predators-here [
          let target one-of predators
          ask target [
            die
          ]]
        [ ask fishes in-radius 3 [
          die
        ]
        ]
      ]
      
      [ ask fishes in-radius 2 [
        die]
      
      ]]
  
end




to fish-reproduce
  ifelse produce-source?                  ;;let fish reproduce. If there required a reproduce source, make the forage fishes can only reproduce at certain place
  [
    let location false                  ;;so every time fish want to reproduce, they have to move towards those sources
    ask patch-here[
      if  pcolor = pink                 ;;and hatch their childeren out side the walls
      [ set location true
      ]]
    
    ifelse location != false
      [  
        if random 100 < fish-reproduce-percent [
          set energy (energy / 2)
          move
          move
          hatch fish-hatch-number [
            hatch 1  [ 
              rt random-float 360 
              let wall? false
              ask patch-ahead 1[
                if(pcolor = red)
                [
                  set wall? true
                ]
              ] 
              ifelse (wall?)
              [
                rt random 360
                move
              ]
              [ fd 1]]]
          
        ]]
      [ 
        
        trace-back ]]            ;;the moving towards sources procedure
  [  if random 100 < fish-reproduce-percent [        ;;otherwise, just normal reproduce. Can happen at any place
    
    set energy (energy / 2)
    hatch fish-hatch-number [
      hatch 1  [ 
        rt random-float 360 
        let wall? false
        ask patch-ahead 1[
          if(pcolor = red)
          [
            set wall? true
          ]
        ] 
        ifelse (wall?)
        [
          rt random 360
          move
        ]
        
        [forward 1  ] ] ]
    
    
  ]
  ]
end

to trace-back
  let x 0                   ;;find the way back to the sources and reproduce
  let y 0
  let candidates one-of patches with [pcolor = pink]
  if candidates != nobody
    [ ask one-of patches with [pcolor = pink]
      [
        set x pxcor
        set y pycor
      ]
    facexy x y
    let wall? false
    ask patch-ahead 1[
      if(pcolor = red)
        [
          set wall? true
        ] 
    ] 
    ifelse (wall?)
      [
        rt random 360          ;;if there are walls on them way, they would try to find another path
        move
      ]
      [ fd 1]]
  
end


to predator-reproduce              ;;predators' reproduce, the same with the normal forage fishes' reproduce
  if random 100 < predator-reproduce-percent and energy > 60[
    set energy (energy / 2)
    hatch 1  [ 
      rt random-float 360 
      let wall? false
      ask patch-ahead 1[
        if(pcolor = red)
        [
          set wall? true
        ]
      ] 
      ifelse (wall?)
      [
        rt random 360
        move
      ]
      
      [forward 1  ] ] 
    
  ]
end


to check-if-dead          ;;check whether the predators are dead
  if energy < 5 and age > 10[
    if random 100 < 62
    [
      
      die
      ;ask detritus [hatch 2]
    ]
  ]
end

to check-fish-dead     ;; check whether the forage fishes are dead
  if energy < 1 [
    die
  ]
end


to regrow-plankton      ;;regrow the planktons after certain amount of time and possibilities
  ask patches with [ pcolor = blue][
    if  random 100 < sea-regrow-time
      [ set pcolor green
        set plankton sea-regrow-time]]
  
  ask patches with [pcolor = green]   [set plankton plankton - 1]
  
  
end



to my-update-plots
  set-current-plot-pen "fish"
  plot count fishes
  set-current-plot-pen "shark"
  plot count predators  ;; scaling factor so plot looks nice
  set-current-plot-pen "plankton"
  plot sum [plankton] of patches / 30 ;; scaling factor so plot looks nice end
end

to boat-move        ;;let boats moving around without hitting the walls
  rt random 360
  let wall? false
  ask patch-ahead 1[
    if(pcolor = red)
    [
      set wall? true
    ]
  ] 
  ifelse (wall?)
  [
    rt random 360
    move
  ]
  
  [forward 1  ]
end

to move            ;;let turtles moving without hitting the walls
  rt random 360
  
  let wall? false
  ask patch-ahead 1[
    if(pcolor = red)
    [
      set wall? true
    ]
  ] 
  ifelse (wall?)
  [
    rt random 360
    move
  ]
  
  [forward 1  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
570
10
1009
470
16
16
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
15
22
81
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
192
23
255
56
NIL
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
72
187
105
number-of-fish
number-of-fish
0
200
112
1
1
NIL
HORIZONTAL

SLIDER
15
124
197
157
number-of-predator
number-of-predator
0
100
3
1
1
NIL
HORIZONTAL

SLIDER
15
175
240
208
predator-reproduce-percent
predator-reproduce-percent
0
60
2
1
1
NIL
HORIZONTAL

SLIDER
15
228
217
261
fish-reproduce-percent
fish-reproduce-percent
0
100
22
1
1
NIL
HORIZONTAL

PLOT
21
339
276
529
population over time
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"shark" 1.0 0 -16777216 true "" ""
"fish" 1.0 0 -2674135 true "" ""
"plankton" 1.0 0 -13840069 true "" ""

SLIDER
20
277
193
310
fish-hatch-number
fish-hatch-number
1
8
1
1
1
NIL
HORIZONTAL

SWITCH
200
72
303
105
flock?
flock?
1
1
-1000

SWITCH
257
224
429
257
human-involoved?
human-involoved?
0
1
-1000

SLIDER
362
364
559
397
predator-fight-percent
predator-fight-percent
0
100
2
1
1
NIL
HORIZONTAL

BUTTON
432
27
537
60
NIL
draw-island
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
418
417
557
450
mouse-down
mouse-down
0
1
-1000

SLIDER
387
471
559
504
sea-regrow-time
sea-regrow-time
0
100
5
1
1
NIL
HORIZONTAL

SLIDER
376
267
558
300
fish-gain-from-food
fish-gain-from-food
0
100
6
1
1
NIL
HORIZONTAL

SLIDER
346
315
559
348
predator-gain-from-food
predator-gain-from-food
0
100
11
1
1
NIL
HORIZONTAL

SLIDER
257
175
429
208
boats-number
boats-number
0
100
0
1
1
NIL
HORIZONTAL

BUTTON
101
22
171
55
NIL
create
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
430
224
557
257
prefer-big?
prefer-big?
1
1
-1000

SWITCH
227
124
330
157
chase?
chase?
1
1
-1000

BUTTON
431
81
542
114
NIL
draw-source
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
396
524
560
557
produce-source?
produce-source?
1
1
-1000

BUTTON
314
28
420
61
NIL
polution-on
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
427
135
547
168
NIL
draw-polution
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
317
82
422
115
NIL
self-restore
T
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

This is a model simulating a marine ecosystem and let users try several human activities and see the result returned by the model.
Details:
In my models, there are two main focuses. The first is how would human beings’ behaviors impact on the ecosystem at continental shelf. In this study, I involved in 3 factors in total: building an island on the sea surface, fishing with boats moving around, emit wastes and pollution to the sea.
The second is the fishes’ behavior. In this study, I implemented a lot of fishes’ normal habits and its relationship with predators. I observe their moving patterns under several varied different situations. 


## HOW IT WORKS

Rules
For forage fishes: it has the option to form a flock to act and move together which in the real world would help fish for reducing the resistance produced by water and would also help forage fishes to escape from its predators. Besides the flock feature, the fishes can also choose avoid action to detect nearby predators and escape to another direction. Every move would reduce their energy by one and if the possibility is big enough, they can reproduce which would cost them half energy. The hatch number is controlled by the fish-reproduce-percent slider. The fishes can eat seaweed and gain energy. And the energy is also determined by a slider named fish-gain-from-food.
For predators: They can chase after the forage fishes for food and if there is no fish nearby but some other predators nearby, they would fight with each other and one of them would die. Predators can eat fishes to gain energy and reproduce at a certain possibility that would lose half of its energy. If the age of predator is over 10 or its energy is less than 5, it would die. Every move would also make predator’s age plus one.

For human-beings: there is an option to decide whether the human would be involved in this ecosystem. If human-involved is false, the system would only have predators and forage fishes which would form a balanced ecosystem. If human-involved is true, the system would have boats moving around and catching predators and fishes. The boats’ speed is higher than fishes and when there is a predator nearby, the boat would prefer catching a predator rather than all the fishes in radius 3. 
For plankton: Their color is green. Forage fishes are feed on the planktons. And planktons can regrow randomly in a certain amount of time. When they are eaten by the fishes, they would disappear and pcolor would go back to blue.

Activities
Drawing an island:
The users can turn a patch into color red, which means building an island on the ocean. These parts are not accessible by any kinds of fish or boats.
We can use this feature to study how would the size of the island effect all the ecosystem around continental shelf. 
Emit pollution:
The users can turn a patch into color grey, which means make that part of ocean too dirty for plankton to live on. So at the grey patches, plankton would not grow there. However, the ocean has an ability to clean it self. When the water turns back to blue the plankton would regrow again.
Fish migrations:
The users can turn a patch into color pink, which means it is a place for forage fishes to reproduce. No forage fish can reproduce at plankton or blue. We can draw several sources for fishes and observe their movings.



## HOW TO USE IT

The first step to study how will human would affect a system, we need to have the precondition that the whole ecosystem is balanced. 
So first, we have to set my model to be balanced only with the fish, predators and planktons. This is easy to achieve. 
For second step, we can try flock? slider or chase? Slider to see whether these natural features would make one side has any advantage.
For third step, we can draw island on the screen and see how the size of the island affects the whole ecosystem.
For the following steps, we can try draw the source for forage fishes or draw the pollution. 
Then we can combine these three features to see the impact. For example, we can draw the island surround the reproduce source which makes no forage fishes can reach the source for reproducing and see what is the result. Or we can draw four sources and a straight island cross them. 
There are a lot of interesting features and phenomena exist in my model.


## THINGS TO NOTICE

When we want to circle a piece of island, we have to make sure there are no cracks.

## THINGS TO TRY

We can draw the island surround the reproduce source which makes no forage fishes can reach the source for reproducing and see what is the result. Or we can draw four sources and a straight island cross them. Details have been writen in the how to use it.

## EXTENDING THE MODEL

May be would add the marine current flow in which would change the distributions of the planktons in the future.

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

boat
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

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

flower budding
false
0
Polygon -7500403 true true 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Polygon -7500403 true true 189 233 219 188 249 173 279 188 234 218
Polygon -7500403 true true 180 255 150 210 105 210 75 240 135 240
Polygon -7500403 true true 180 150 180 120 165 97 135 84 128 121 147 148 165 165
Polygon -7500403 true true 170 155 131 163 175 167 196 136

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

molecule hydrogen
true
0
Circle -1 true false 138 108 84
Circle -16777216 false false 138 108 84
Circle -1 true false 78 108 84
Circle -16777216 false false 78 108 84

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

shark
false
0
Polygon -7500403 true true 283 153 288 149 271 146 301 145 300 138 247 119 190 107 104 117 54 133 39 134 10 99 9 112 19 142 9 175 10 185 40 158 69 154 64 164 80 161 86 156 132 160 209 164
Polygon -7500403 true true 199 161 152 166 137 164 169 154
Polygon -7500403 true true 188 108 172 83 160 74 156 76 159 97 153 112
Circle -16777216 true false 256 129 12
Line -16777216 false 222 134 222 150
Line -16777216 false 217 134 217 150
Line -16777216 false 212 134 212 150
Polygon -7500403 true true 78 125 62 118 63 130
Polygon -7500403 true true 121 157 105 161 101 156 106 152

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
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <steppedValueSet variable="number-of-predator" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="number-of-fish">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="produce-source?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="human-involoved?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-gain-from-food">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fish-hatch-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fish-reproduce-percent">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-reproduce-percent">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prefer-big?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-fight-percent">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chase?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flock?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boats-number">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mouse-down">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sea-regrow-time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fish-gain-from-food">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="number-of-predator">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-fish">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="produce-source?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="human-involoved?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-gain-from-food">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fish-hatch-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fish-reproduce-percent">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-reproduce-percent">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prefer-big?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-fight-percent">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chase?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flock?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="boats-number" first="3" step="5" last="40"/>
    <enumeratedValueSet variable="mouse-down">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sea-regrow-time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fish-gain-from-food">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup
create</setup>
    <go>go</go>
    <exitCondition>ticks = 1500</exitCondition>
    <metric>count fishes</metric>
    <enumeratedValueSet variable="number-of-predator">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-fish">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="produce-source?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="human-involoved?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-gain-from-food">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fish-hatch-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fish-reproduce-percent">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-reproduce-percent">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prefer-big?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-fight-percent">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chase?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flock?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="boats-number" first="24" step="3" last="28"/>
    <enumeratedValueSet variable="mouse-down">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sea-regrow-time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fish-gain-from-food">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
