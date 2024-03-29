;
; Nom : Les chasseurs-cueilleurs
; Description : Ce modèle vise à étudier la stabilité des écosystèmes prédateurs-proies
; en prenant en compte les interactions entre humains, loups et lapins.
; Auteur : FANOMEZANTSOA Herifiandry Marc Nico
; Email : ny.kalash@gmail.com
; Github: https://github.com/ks-krimi
; Année : 2023
; Tags : Examen SMA, EMIT Fianarantsoa, M2I
; Enseignant : Docteur RAKOTONIRAINY Hasina
;

globals [
  energie-chasse
  energie-cueillette

  radius
]

breed [ persons person ]
breed [ loups loup ]
breed [ lapins lapin ]

breed [ fruits fruit ]
breed [ legumes legume ]

turtles-own [ energy velocity tronpher ]
persons-own [ instinct revenir-au-village? ]
patches-own [ category fertilite ]


to-report village_zone
  report pxcor > -3  and pycor > -3 and pxcor < 3 and pycor < 3
end

to-report taniere_zone
  report pxcor > -16  and pycor > 12 and pxcor < -12 and pycor < 16
end

to-report cueillette_zone
  report pxcor > 9  and pycor > 12 and pxcor < 16 and pycor < 16
end

to create_lapin
  create-lapins nb-lapin-init [
    setxy random-xcor random-ycor
    set shape "rabbit"
    set color violet
    set energy energy-init-lapin
    set velocity 0.4
  ]
end

to create_10_lapin
  create-lapins 10 [
    setxy random-xcor random-ycor
    set shape "rabbit"
    set color violet
    set energy energy-init-lapin
    set velocity 0.4
  ]
end

to setup
  clear-all

  set radius 1.5

  setup-environement
  create_lapin

  reset-ticks
end

to play
  if not any? persons [ user-message "Tsy misy olona tavela intsony" stop ]
  if not any? lapins and not any? persons [ user-message "Tsy misy lapin sy olona tavela intsony" stop ]
  if energie-chasse >= 50 and not any? lapins [ create_10_lapin set energie-chasse energie-chasse - 50 ]
  if energie-cueillette >= 50 and not any? lapins [ create_10_lapin set energie-cueillette energie-cueillette - 50 ]

  ask turtles [
    wiggle
    check-if-dead
    eat
    reproduce
    go_home
  ]
  regrow-grass

  tick
  plots
end

to setup-environement
  ask patches [
    set category "grass"
    set fertilite random-float 5
    recolor-grass
  ]

  regrow-grass

  ask patches with [ cueillette_zone ]
  [
    sprout-fruits 1 [
      set shape "tree"
      set color lime
    ]
  ]

  ask n-of nb-villageois-init patches with [ village_zone ]
  [
    sprout-persons 1 [
      set size 1.5
      set energy energy-init-person
      set velocity 0.5
      set instinct one-of ["cueilleur" "chasseur"]
      ifelse instinct = "cueilleur" [ init-cuilleur ] [ init-chasseur ]
    ]
    sprout 1 [ setxy 0 0 set shape "campsite" set color white set size 3 ]
  ]

  ask n-of nb-loups-init patches with [ taniere_zone ]
  [
    sprout-loups 1 [
      set shape "wolf"
      set color red
      set size 1.6
      set energy energy-init-loup
      set velocity 0.6
    ]
  ]

  trace-village
  trace-taniere
  trace-cueillette
end

to init-cuilleur
  set shape "person"
  set color yellow
end

to init-chasseur
  set shape "person"
  set color pink
end

to trace-village
  ask patches with [ village_zone ]
  [
    ask neighbors [
      set pcolor brown
      set fertilite 0
      set category "village"
    ]
  ]
end

to trace-taniere
  ask patches with [ taniere_zone ]
  [
    ask neighbors [
      set pcolor scale-color brown 1 5 0
      set fertilite 0
      set category "taniere"
    ]
  ]
end

to trace-cueillette
  ask patches with [ cueillette_zone ]
  [
    ask neighbors [
      set category "cueillette"
      set fertilite 10
      recolor-grass
    ]
  ]
end

to recolor-grass
  set pcolor scale-color green (10 - fertilite) -5 10
end

to eat
  if breed = lapins [ if energy <= energy-init-lapin + ( energy-init-lapin * taux-de-reproduction ) [ eat-grass ] ]
  if breed = persons [
    if energy < energy-init-person
    [ ifelse instinct = "chasseur"
      [ chasser if energy < energy-init-person / 4 [ cueillir ] ]
      [ cueillir ]
    ]
  ]
  if breed = loups [ if energy < energy-init-loup [ chasser eat_or_killed_by_person ] ]
end

to cueillir
  if any? other turtles in-radius radius with [ shape = "tree" or shape = "flower budding" ] [
    let nearby_legumes min-one-of other legumes in-radius radius [ distance myself ]
    let nearby_fruits min-one-of other fruits in-radius radius [ distance myself ]

    ask persons-here [
      if nearby_legumes != nobody and member? nearby_legumes turtles [ face nearby_legumes  ]
      fd velocity
      if any? legumes-here [
        let legumes_attraper one-of legumes-here
        ask legumes_attraper [
          ask persons-here [
            ;; user-message "cueille legume"
            set energy energy + 4
            set tronpher tronpher + 2
          ]
          ask patch-here [
            set fertilite 1
          ]
        ]
      ]
    ]

    ask persons-here [
      if nearby_fruits != nobody and member? nearby_fruits turtles [ face nearby_fruits  ]
      fd velocity
      if any? fruits-here [
        let fruits_attraper one-of fruits-here
        ask fruits_attraper [
          ask persons-here [
            ;; user-message "cueille fruit"
            set energy energy + 6
            set tronpher tronpher + 4
          ]
          ask patch-here [
            set fertilite 1
          ]
          ;; die
        ]
      ]
    ]
  ]
end

to chasser
  if any? other turtles in-radius radius with [ shape = "rabbit" ] [

    let nearby_rabbit min-one-of other lapins in-radius radius [ distance myself ]

    ask loups-here [
      if nearby_rabbit != nobody and member? nearby_rabbit turtles [ face nearby_rabbit  ]
      fd velocity
      if any? lapins-here [
        let lapin_attraper one-of lapins-here
        ask lapin_attraper [
          ask loups-here [
            set energy energy + ( energy-gain-from-rabbit * 2 )
            set tronpher tronpher + ( energy-gain-from-rabbit * 2 )
          ]
          die
        ]
      ]
    ]

    ask persons-here [
      if nearby_rabbit != nobody and member? nearby_rabbit turtles [ face nearby_rabbit  ]
      fd velocity
      if any? lapins-here [
        let lapin_attraper one-of lapins-here
        ask lapin_attraper [
          ask persons-here [
            set energy energy + ( energy-gain-from-rabbit * 2 )
            set tronpher tronpher + energy-gain-from-rabbit
          ]
          die
        ]
      ]
    ]
  ]
end

to eat_or_killed_by_person
  if any? other turtles in-radius radius with [ shape = "person" ] [

    let nearby_person min-one-of other persons in-radius radius [ distance myself ]

    ask loups-here [
      if nearby_person != nobody and member? nearby_person turtles [ face nearby_person  ]
      fd velocity
      if any? persons-here [
        let prs_attraper one-of persons-here
        ask prs_attraper [
          ifelse [energy] of myself > [energy] of prs_attraper
          [
            ask loups-here [
              set energy energy + ( [energy] of prs_attraper * 30 / 100 )
              set tronpher tronpher + ( [energy] of prs_attraper * 40 / 100 )
            ]
            die
          ]
          [
            if [energy] of myself < [energy] of prs_attraper [
              ask loups-here [
                ask prs_attraper [
                  set energy energy + ( [energy] of myself * 20 / 100 )
                  set tronpher tronpher + ( [energy] of myself * 30 / 100 )
                ]
                die
              ]
            ]
          ]
        ]
      ]
    ]
  ]
end

to eat-grass
  if ( fertilite >= energy-gain-from-grass ) [
    set energy energy + energy-gain-from-grass
    set fertilite fertilite - energy-gain-from-grass
  ]
end

to-report grass_growing_rate [ saisons ]
  let rate 0
  if saisons = "Été" [ set rate 0.05 ]
  if saisons = "Printemps" [ set rate 0.03 ]
  if saisons = "Automne" [ set rate 0.02 ]
  if saisons = "Hiver" [ set rate 0.01 ]
  report rate
end

to regrow-grass
  ask patches with [not (taniere_zone or village_zone or cueillette_zone)] [
    set fertilite fertilite + grass_growing_rate Saison
    if fertilite >= 10 [
      set fertilite 10
    ]
    if category = "grass" [ recolor-grass ]
    if fertilite >= 8 and not any? legumes-here [
      sprout-legumes 1 [
        set shape "flower budding"
        set color lime
      ]
    ]
    if fertilite < 8 [ ask legumes-here [ die ] ]

  ]
end

to go_home
  ask persons with [ tronpher >= 30 ] [
    set color black
    let village one-of patches with [ category = "village" ]
    face village
    if patch-here = village [
      if instinct = "chasseur" [
        set energie-chasse energie-chasse + 1
        set tronpher 0
        set color pink
        set energy energy-init-person
        hatch 1 [
          set instinct one-of [ "cueilleur" "chasseur"]
          ifelse instinct = "cueilleur" [ set color yellow ] [ set color pink ]
          set energy energy-init-person
        ]
      ]
      if instinct = "cueilleur" [
        set energie-cueillette energie-cueillette + 1
        set tronpher 0
        set color yellow
        set energy energy-init-person
        hatch 1 [
          set instinct one-of ["cueilleur" "chasseur"]
          ifelse instinct = "cueilleur" [ set color yellow ] [ set color pink ]
          set energy energy-init-person
        ]
      ]
    ]

    ask loups with [ tronpher >= 30 ]
    [
      set color black
      let taniere one-of patches with [ category = "taniere" ]
      face taniere
      if patch-here = taniere [
        set tronpher 0
        set color red
        set energy energy-init-loup
        hatch 1 [
          set energy energy-init-loup
        ]
      ]
    ]

  ]
end

to wiggle
  forward velocity
  right random 90
  left random 90
  set energy energy - 1
end

to check-if-dead
 if energy < 0 and breed != fruits and breed != legumes and shape != "campsite"  [
    die
  ]
end

to reproduce
  if breed = lapins and energy >= energy-init-lapin + ( energy-init-lapin * taux-de-reproduction ) [
    hatch 1 [
      set energy energy-init-lapin
   ]
   set energy energy-init-lapin
  ]
  if breed = loups and energy > energy-init-loup + 50  [  ]
  if breed = persons and energy > energy-init-person + 50 [  ]
end

to plots
  set-current-plot  "Évolution de la population"
  set-current-plot-pen "Cueilleur"
  plot count persons with [ instinct = "cueilleur" ]

  set-current-plot-pen "Chasseur"
  plot count persons with [ instinct = "chasseur" ]

  set-current-plot-pen "Lapin"
  plot count lapins

  set-current-plot-pen "Loup"
  plot count loups

  set-current-plot  "Énergie du village"
  set-current-plot-pen "Énergie de cueillette"
  plot energie-cueillette

  set-current-plot-pen "Énergie de chasse"
  plot energie-chasse
end


; Copyright 2023 FANOMEZANTSOA Herifiandry Marc Nico.
@#$#@#$#@
GRAPHICS-WINDOW
380
10
817
448
-1
-1
13.0
1
10
1
1
1
0
0
0
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
229
305
372
338
Mise en place
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

SLIDER
7
200
180
233
nb-villageois-init
nb-villageois-init
0
25
25.0
1
1
NIL
HORIZONTAL

MONITOR
830
350
973
395
Nombre de cuilleurs
count persons with [ instinct = \"cueilleur\" ]
17
1
11

MONITOR
829
402
1048
447
Nombre de chasseurs
count persons with [ instinct = \"chasseur\" ]
17
1
11

PLOT
827
11
1332
238
Évolution de la population
Temps
Populations
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Cueilleur" 1.0 0 -1184463 true "" ""
"Chasseur" 1.0 0 -2064490 true "" ""
"Lapin" 1.0 0 -8630108 true "" ""
"Loup" 1.0 0 -2674135 true "" ""

CHOOSER
7
28
165
73
Saison
Saison
"Printemps" "Été" "Automne" "Hiver"
1

SLIDER
7
159
179
192
nb-loups-init
nb-loups-init
0
9
9.0
1
1
NIL
HORIZONTAL

BUTTON
228
346
372
379
Démarrer
play
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
13
321
220
354
energy-gain-from-grass
energy-gain-from-grass
2
8
4.0
0.1
1
NIL
HORIZONTAL

PLOT
970
246
1332
396
Énergie du village
Temps
Énergie
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Énergie de chasse" 1.0 1 -2064490 true "" ""
"Énergie de cueillette" 1.0 1 -1184463 true "" ""

SLIDER
12
279
218
312
energy-gain-from-rabbit
energy-gain-from-rabbit
2
20
5.0
1
1
NIL
HORIZONTAL

INPUTBOX
188
98
372
158
energy-init-person
100.0
1
0
Number

INPUTBOX
188
30
373
90
energy-init-loup
200.0
1
0
Number

INPUTBOX
188
165
372
225
energy-init-lapin
80.0
1
0
Number

SLIDER
13
362
220
395
taux-de-reproduction
taux-de-reproduction
0.1
1
0.1
0.1
1
%
HORIZONTAL

SLIDER
6
117
175
150
nb-lapin-init
nb-lapin-init
10
100
80.0
1
1
NIL
HORIZONTAL

MONITOR
1054
403
1198
448
Nombre de légumes
count legumes
17
1
11

MONITOR
1199
403
1332
448
Nombre de fruits
count fruits
17
1
11

MONITOR
829
298
965
343
Nombre de loups
count loups
17
1
11

MONITOR
828
246
964
291
Nombre de lapins
count lapins
17
1
11

TEXTBOX
8
10
158
28
Choix de la saison
12
0.0
1

TEXTBOX
191
10
374
40
Définition de l'énergie initiale
12
0.0
1

TEXTBOX
4
95
188
113
Définition de la valeur initiale
12
0.0
1

TEXTBOX
13
257
217
277
Définition des variables globales
12
0.0
1

TEXTBOX
273
280
321
298
Actions
12
0.0
1

TEXTBOX
1062
456
1326
480
Avec 🧡 par FANOMEZANTSOA Herifiandry Marc Nico.\n© 2023 
10
0.0
1

@#$#@#$#@
## Les chasseurs-cueilleurs

Ce modèle vise à étudier la stabilité des écosystèmes prédateurs-proies en prenant en compte les interactions entre humains, loups et lapins.

## Auteur

FANOMEZANTSOA Herifiandry Marc Nico

## Comment ça fonctionne

Voici comment fonctionne ce modèle :

  - Les loups mangent des humains et des lapins.
  - Les humains mangent des fruits et des légumes.
  - Les humains peuvent tuer les loups si leur énergie est supérieure à celle du loup.
  - Les lapins mangent des légumes.

## Comment l'utiliser

Voici comment vous pouvez l'utiliser :

  - Vous pouvez ajuster les paramètres en fonction de la simulation que vous souhaitez.
  - Observez l'évolution de la population dans le graphique.
  - Consultez l'état de l'énergie du village.
  - Visualisez les nombres et l'état des agents pendant l'exécution de la simulation.



## Points à remarquer

  - Si tous les humains meurent, la simulation s'arrête.

  - Le taux de reproduction varie entre 0,1 et 1,0. Si le taux est de 0,1, cela signifie que les agents vont se reproduire beaucoup. Si le taux est de 1,0, le taux de reproduction sera faible, à l'inverse. (Faites attention)

## Ce que vous pouvez essayer

Voici ce que vous pouvez essayer :

  - Changer la saison dans la SELECT.
  - Définir les valeurs initiales des agents à l'aide des SLIDER.
  - Définir l'énergie initiale des à l'aide des TEXT INPUT.
  - Définir les variables globales à l'aide des SLIDER.
  - Appuyer sur le boutons **'Mise en place'** pour configurer l'environnement avant d'appuyer sur le bouton **'Démarrer'**.
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

campsite
false
0
Polygon -7500403 true true 150 11 30 221 270 221
Polygon -16777216 true false 151 90 92 221 212 221
Line -7500403 true 150 30 150 225

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

rabbit
false
0
Polygon -7500403 true true 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -7500403 true true 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -7500403 true true 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -7500403 true true 49 89 57 47 78 4 89 20 70 88
Circle -16777216 true false 37 103 16
Line -16777216 false 44 150 104 150
Line -16777216 false 39 158 84 175
Line -16777216 false 29 159 57 195
Polygon -5825686 true false 0 150 15 165 15 150
Polygon -5825686 true false 76 90 97 47 130 32
Line -16777216 false 180 210 165 180
Line -16777216 false 165 180 180 165
Line -16777216 false 180 165 225 165
Line -16777216 false 180 210 210 240

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
NetLogo 6.3.0
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
