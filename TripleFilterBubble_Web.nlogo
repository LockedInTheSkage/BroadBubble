extensions [array]
breed [guys guy]
breed [infobits infobit]
undirected-link-breed [friends friend]
undirected-link-breed [infolinks infolink]
undirected-link-breed [seenlinks seenlink]

guys-own [group is-influencer feed feed-pointer]
infobits-own [popularity likes]

to setup
  clear-all
  if network-type = "groups" [
    create-guys numguys [ initialize-guy ]
    ask guys [ set group random numgroups ]
    ask guys [ make-group-network ]
  ]
  visualize
  reset-ticks
end

to go
  new-infobits ; Step 1
  if friend-posting-probability > 0 or influencer-dominance > 0 [ ask guys [ post-infobit ] ] ; Step 2
  if birth-death-probability > 0 [ birth-death ] ; Step 3.1
  if refriend-probability > 0 [ refriend ] ; Step 3.2
  if feed-system [
    ask guys [choose-feed-info]
  ]
  update-infobits
  visualize

  if ticks mod update-plots-every = 0 [
    update-plots
  ]

  tick-advance 1
  if ticks = stop-tick [
    stop
  ]
end

to choose-feed-info
  let record-pop 0
  let popular-info "null"
  let index 0
  let pop-index 0
  let valued-amount 0
  foreach array:to-list feed [
    [the-info] ->
    if the-info != "null" and the-info != nobody [
      let info-pop 0
      if like-mode = "views" [
        set info-pop [popularity] of the-info
      ]
      if like-mode = "likes" or like-mode = "likes and dislikes" [
        set info-pop [likes] of the-info
      ]

      if (record-pop <= info-pop) [
        set valued-amount (valued-amount + 1)
        set record-pop info-pop
        set popular-info the-info
        set pop-index index
      ]
    ]
    set index (index + 1)
  ]
  if popular-info != "null"[
    array:set feed pop-index "null"
    integrate popular-info
  ]
end

to make-group-network ;; for individuals
  let me self
  let p numfriends / numguys
  let p-inter ifelse-value (fraction-inter = 0) [0] [numgroups * p / ( (1 - fraction-inter) / fraction-inter + numgroups - 1)] ;; calculation to ensure that expected total number of friends fits numfriends
  let p-intra ifelse-value (fraction-inter = 0) [p * numgroups] [p-inter * (1 - fraction-inter) / fraction-inter] ;; calculation to ensure that expected total number of friends fits numfriends
  ask other guys [
    if friend-neighbor? myself [ask link-with myself [ die ] ]
    ifelse (group = [group] of myself) [
      if (random-float 1 < p-intra) [ create-friend-with myself [set color yellow]]
    ] [
      if (random-float 1 < p-inter) [ create-friend-with myself [set color yellow]]
    ]
  ]
end

to new-infobits
  (ifelse new-info-mode = "central" [
    create-infobits numcentral [
      initialize-infobit
      ask guys [ try-integrate-infobit myself ]
    ]
  ] new-info-mode = "individual" [
    ask guys [ create-and-spread-infobit ]
  ] [
    let neutral-infobit nobody
    if new-info-mode = "balanced with neutral" [
      create-infobits 1 [
        initialize-infobit
        ; This kinda works, but creates a central blob that outer agents are too far away to want to join.
        ; setxy random-xcor / 3 ifelse-value (dims = 1) [0] [random-ycor / 3]
        ; With a gaussian, they are more likely to see information which guides them into the right direction.
        setxy max list min-pxcor min list max-pxcor (random-normal 0 6) max list min-pycor min list max-pycor (random-normal 0 6)
        set neutral-infobit self
      ]
    ]
    let is-balanced-mode (substring new-info-mode 0 8 = "balanced")
    ask guys [
      let selection-mode new-info-mode
      if is-balanced-mode [
        ifelse balanced-close-probability > random-float 1 [
          set selection-mode "select close infobits" ; use existing implementation
        ] [
          if new-info-mode = "balanced with distant" [
            set selection-mode "select distant infobits"
          ]
          if new-info-mode = "balanced with neutral" [
            ; will not trigger code below, instead create neutral information
            try-integrate-infobit neutral-infobit
          ]
        ]
      ]
      if selection-mode = "select close infobits" or selection-mode = "select distant infobits" or selection-mode = "select nearish infobits" [
        ifelse count infobits < numguys [
          create-and-spread-infobit
        ] [
          let fitting-infobits no-turtles
          ifelse selection-mode = "select nearish infobits" [
            set fitting-infobits infobits in-radius (1.5 * acceptance-latitude * (max-pxcor + 0.5)) with [0.75 * acceptance-latitude < distance myself / (max-pxcor + 0.5)]
          ] [
            let close-infobits infobits in-radius (acceptance-latitude * (max-pxcor + 0.5))
            set fitting-infobits (ifelse-value
              selection-mode = "select close infobits"
              [close-infobits]
              selection-mode = "select distant infobits"
              [infobits with [not member? self close-infobits]]
            )
          ]
          set fitting-infobits fitting-infobits with [not infolink-neighbor? myself and self != neutral-infobit]
          ifelse fitting-infobits = no-turtles [
            create-and-spread-infobit
          ] [
            try-integrate-infobit one-of fitting-infobits
          ]
        ]
      ]
    ]
  ])
end

to create-and-spread-infobit
  hatch-infobits 1[
    initialize-infobit
    ask myself [try-integrate-infobit myself] ; first myself is guy, second myself is the new infobit
  ]
end

to initialize-guy
  set shape "dot"
  set size 3
  setxy random-xcor  ifelse-value (dims = 1) [0] [random-ycor]
  set is-influencer random-float 1 < influencer-share
  set feed array:from-list n-values feed-size ["null"]
  set feed-pointer 0
end

to initialize-infobit
  set shape "dot"
  set color grey
  setxy random-xcor ifelse-value (dims = 1) [0] [random-ycor]
  set popularity 0
  set likes 0
end

to post-infobit
  if any? infolink-neighbors [
    let postedinfo one-of infolink-neighbors
    ifelse is-influencer [
      ask other guys [ if influencer-dominance > random-float 1 [try-integrate-infobit postedinfo] ]
    ][
      ask friend-neighbors [ if friend-posting-probability > random-float 1 [try-integrate-infobit postedinfo] ]
    ]
]
end

to integrate [newinfobit]
  if like-rate > random-float 1 [
    ask newinfobit [ set likes (likes + 1) ]
  ]
  if not infolink-neighbor? newinfobit [
    if count my-infolinks >= memory [ ask one-of my-infolinks [die] ]
    create-infolink-with newinfobit
    if less-rewatch [
      create-seenlink-with newinfobit
    ]
    setxy mean [xcor] of infolink-neighbors mean [ycor] of infolink-neighbors
  ]
end

to try-integrate-infobit [newinfobit]
  if (not less-rewatch) or (rewatch-rate > random-float 1 or not seenlink-neighbor? newinfobit) [
    ifelse (random-float 1 < integration-probability (distance newinfobit / (max-pxcor + 0.5)) acceptance-latitude acceptance-sharpness) [
      if like-rate > random-float 1 [
        ask newinfobit [ set likes (likes + 1) ]
      ]
      ifelse feed-system [
        array:set feed feed-pointer newinfobit
        set feed-pointer (feed-pointer + 1)
        if feed-pointer = feed-size [
          set feed-pointer 0
        ]
      ][
        integrate newinfobit
      ]
    ][
      if dislike-rate > random-float 1 and (like-mode = "likes and dislikes") [
        ask newinfobit [ set likes (likes - 1) ]
      ]
    ]
  ]
end

to birth-death ;; for individuals
  ask guys [if random-float 1 < birth-death-probability [
    initialize-guy
    ask my-infolinks [die]
  ]]
end

to refriend
  ask friends [
    if random-float 1 < refriend-probability * (1 - integration-probability (link-length / (max-pxcor + 0.5)) acceptance-latitude acceptance-sharpness ) [
      let me one-of both-ends
      ask me [
        let potential-new-friends other (turtle-set [friend-neighbors with [not friend-neighbor? me]] of friend-neighbors)
        if potential-new-friends = no-turtles [set potential-new-friends (turtle-set one-of guys with [not friend-neighbor? me])]
        create-friend-with one-of potential-new-friends [set color yellow]
      ]
      die
  ]]
end

to update-infobits
  ask infobits [
    ifelse (any? infolink-neighbors) [
      set popularity count infolink-neighbors
      ifelse infobit-size [set size sqrt popularity] [set size 1]
    ] [
     die
  ]]
end

to visualize
  ifelse show-people [ask guys [show-turtle]] [ask guys [hide-turtle]]
  ifelse show-infobits [ask infobits [show-turtle]] [ask infobits [hide-turtle]]
  ifelse show-infolinks [ask infolinks [show-link]] [ask infolinks [hide-link]]
  ifelse show-seenlinks [ask seenlinks [show-link]] [ask seenlinks [hide-link]]
  ifelse show-friend-links [ask friends [show-link]] [ask friends [hide-link]]
  ifelse patch-color = "white" or count infobits = 0 [
    ask patches [set pcolor white]
  ][
    if patch-color = "frequency infobits" and count infobits > 0 [ask patches [set pcolor scale-color gray (count infobits-here / count infobits) color-axis-max 0]]
    if patch-color = "frequency guys" [ask patches [set pcolor scale-color blue (count guys-here / count guys) color-axis-max 0]]
  ]
end

to re-color-group
  ask guys [set color group * 30 + 25]
end

to re-color-influencer
  ask guys [
    ifelse is-influencer [
      set color red
    ][
      set color [128 128 128 60]
    ]
  ]
end

to baseline-settings
  set memory 20
  set acceptance-latitude 0.3
  set acceptance-sharpness 20
  set numguys 125
  set numfriends 5
  set network-type "groups"
  set numgroups 4
  set fraction-inter 0.2
  set dims 2
  set birth-death-probability 0
  set refriend-probability 0
  set balanced-close-probability 0.7
  set numcentral 2
  set stop-tick 10000
  set update-plots-every 200
  set influencer-share 0.01
  set influencer-dominance 0.0
  set friend-posting-probability 0.0
  set like-rate 0.6
  set dislike-rate 0.1
  set feed-system false
end

to baseline-visualization
  set show-people true
  set show-infobits false
  set infobit-size false
  set show-infolinks false
  set show-seenlinks false
  set show-friend-links false
  set patch-color "white"
  set color-axis-max 0.05
end

to-report integration-probability [dist lambda k]
  report lambda ^ k / (dist ^ k + lambda ^ k)
end
@#$#@#$#@
GRAPHICS-WINDOW
457
43
894
481
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
1
1
1
ticks
30.0

TEXTBOX
965
12
1189
38
Visualization parameters
18
14.0
1

SWITCH
960
42
1218
75
show-people
show-people
0
1
-1000

SWITCH
960
78
1098
111
show-infobits
show-infobits
1
1
-1000

SWITCH
1100
78
1218
111
infobit-size
infobit-size
1
1
-1000

SWITCH
960
114
1098
147
show-infolinks
show-infolinks
0
1
-1000

SWITCH
1100
114
1218
147
show-seenlinks
show-seenlinks
1
1
-1000

SWITCH
960
150
1218
183
show-friend-links
show-friend-links
1
1
-1000

CHOOSER
960
222
1218
267
patch-color
patch-color
"white" "frequency infobits" "frequency guys"
0

SLIDER
960
274
1218
307
color-axis-max
color-axis-max
0.001
0.05
0.05
0.001
1
NIL
HORIZONTAL

PLOT
282
42
442
163
guys' infolinks
infos
NIL
0.0
40.0
0.0
10.0
false
false
"" "set-plot-x-range 0 10.5 * ceiling (max (fput 1 [count my-infolinks] of guys) / 10)\nset-plot-y-range 0 count guys / 5"
PENS
"default" 1.0 1 -16777216 true "" "histogram [count my-infolinks] of guys"

PLOT
283
212
443
333
guys' friends
friends
NIL
0.0
22.0
0.0
10.0
true
false
"" "set-plot-x-range 0 1 + max (fput 1 [count my-friends] of guys)\nset-plot-y-range 0 count guys / 5"
PENS
"default" 1.0 1 -16777216 true "" "histogram [count my-friends] of guys"

PLOT
283
335
443
455
infobits
popularity
NIL
0.0
300.0
0.0
10.0
true
false
"" "set-plot-x-range 0 max (fput 1 [popularity] of infobits)"
PENS
"default" 1.0 1 -16777216 true "" "histogram [popularity] of infobits"

TEXTBOX
564
498
728
521
Output measures
18
14.0
1

PLOT
462
530
914
794
spread measures guys
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" "set-plot-y-range 0 1"
PENS
"mean distance infobits" 1.0 0 -13345367 true "" "plot mean [mean lput 0 [link-length] of infolinks] of guys / (max-pxcor + 0.5)"
"mean distance friends" 1.0 0 -5825686 true "" "plot mean [mean lput 0 [link-length] of friends] of guys  / (max-pxcor + 0.5)"

SLIDER
290
505
436
538
update-plots-every
update-plots-every
1
600
200.0
1
1
NIL
HORIZONTAL

BUTTON
290
550
436
583
groups re-color
re-color-group
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
290
586
436
619
influencer re-color
re-color-influencer
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
290
165
361
210
# friends
count friends
17
1
11

MONITOR
365
165
437
210
# infolinks
count infolinks
17
1
11

MONITOR
290
457
361
502
# infobits
count infobits
17
1
11

MONITOR
365
457
437
502
# seenlinks
count seenlinks
17
1
11

SLIDER
10
50
152
83
numguys
numguys
2
1000
125.0
1
1
NIL
HORIZONTAL

SLIDER
10
86
152
119
numfriends
numfriends
1
40
20.0
1
1
NIL
HORIZONTAL

SLIDER
155
50
252
83
dims
dims
1
2
2.0
1
1
NIL
HORIZONTAL

CHOOSER
10
122
152
167
network-type
network-type
"groups"
0

SLIDER
155
122
252
155
numgroups
numgroups
1
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
10
170
152
203
fraction-inter
fraction-inter
0
1
0.2
0.01
1
NIL
HORIZONTAL

INPUTBOX
10
217
152
277
stop-tick
10000.0
1
0
Number

BUTTON
155
207
252
240
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
155
244
252
277
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

TEXTBOX
14
305
182
323
1) Memory parameters
12
0.0
1

SLIDER
10
326
252
359
acceptance-latitude
acceptance-latitude
0.02
1
0.3
0.02
1
NIL
HORIZONTAL

SLIDER
10
362
252
395
acceptance-sharpness
acceptance-sharpness
0
20
20.0
0.2
1
NIL
HORIZONTAL

SLIDER
10
398
252
431
memory
memory
2
40
20.0
1
1
NIL
HORIZONTAL

TEXTBOX
14
442
280
476
2) New infobits\nEach guy perceives one new infobit
12
0.0
1

CHOOSER
10
475
252
520
new-info-mode
new-info-mode
"individual" "central" "select close infobits" "select distant infobits" "select nearish infobits" "balanced with distant" "balanced with neutral"
6

SLIDER
10
523
152
556
balanced-close-probability
balanced-close-probability
0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
155
523
252
556
numcentral
numcentral
1
20
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
14
560
273
578
3) Post one infobit to friend network
12
0.0
1

SLIDER
10
581
252
614
friend-posting-probability
friend-posting-probability
0
1.0
0.0
0.01
1
NIL
HORIZONTAL

TEXTBOX
14
622
191
640
4) Turn-over and refriending
12
0.0
1

SLIDER
10
643
252
676
birth-death-probability
birth-death-probability
0
0.1
0.0
0.002
1
NIL
HORIZONTAL

SLIDER
10
679
252
712
refriend-probability
refriend-probability
0
1
0.0
0.001
1
NIL
HORIZONTAL

TEXTBOX
906
41
929
59
+1
12
0.0
1

TEXTBOX
907
458
922
476
-1
12
0.0
1

TEXTBOX
880
483
900
501
+1
12
0.0
1

TEXTBOX
465
483
480
501
-1
12
0.0
1

TEXTBOX
613
483
763
501
Attitude dimension 1
12
0.0
1

TEXTBOX
903
218
932
262
Att. dim. 2
12
0.0
1

TEXTBOX
10
20
207
45
Setup parameters
18
14.0
1

TEXTBOX
10
276
254
301
Dynamic parameters (go)
18
14.0
1

TEXTBOX
578
13
805
38
Attitude space (World)
18
14.0
1

TEXTBOX
316
14
408
36
Statistics
18
14.0
1

TEXTBOX
960
335
1182
383
Scenario setup \n(Click \"go\" afterwards!)
18
14.0
1

TEXTBOX
960
396
1075
424
Triple Filter Bubble Scenarios
12
0.0
1

BUTTON
960
436
1015
469
1
baseline-settings\nset new-info-mode \"individual\"\nset friend-posting-probability 0.0\nbaseline-visualization\nsetup
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
960
472
1015
505
3
baseline-settings\nset new-info-mode \"individual\"\nset friend-posting-probability 1.0\nbaseline-visualization\nsetup
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
960
522
1015
555
5
baseline-settings\nset new-info-mode \"select close infobits\"\nset friend-posting-probability 0.0\nbaseline-visualization\nsetup
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
960
558
1015
591
7
baseline-settings\nset new-info-mode \"select close infobits\"\nset friend-posting-probability 1.0\nbaseline-visualization\nsetup
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
960
612
1015
645
9
baseline-settings\nset new-info-mode \"individual\"\nset friend-posting-probability 1.0\nset refriend-probability 0.01\nbaseline-visualization\nsetup
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
960
661
1015
694
11
baseline-settings\nset new-info-mode \"individual\"\nset friend-posting-probability 1.0\nset acceptance-latitude 0.5\nbaseline-visualization\nsetup
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
1020
436
1075
469
2
baseline-settings\nset new-info-mode \"central\"\nset friend-posting-probability 0.0\nbaseline-visualization\nsetup
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
1020
472
1075
505
4
baseline-settings\nset new-info-mode \"central\"\nset friend-posting-probability 1.0\nbaseline-visualization\nsetup
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
1020
522
1075
555
6
baseline-settings\nset new-info-mode \"select distant infobits\"\nset friend-posting-probability 0.0\nbaseline-visualization\nsetup
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
1020
558
1075
591
8
baseline-settings\nset new-info-mode \"select distant infobits\"\nset friend-posting-probability 1.0\nbaseline-visualization\nsetup
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
1020
612
1075
645
10
baseline-settings\nset new-info-mode \"individual\"\nset friend-posting-probability 1.0\nset refriend-probability 1\nbaseline-visualization\nsetup
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
1020
661
1075
694
12
baseline-settings\nset new-info-mode \"central\"\nset friend-posting-probability 0.0\nset acceptance-latitude 0.5\nbaseline-visualization\nsetup
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
1100
396
1275
424
Broadening the Bubble Scenarios
12
0.0
1

BUTTON
1100
436
1155
469
A1
baseline-settings\nset new-info-mode \"individual\"\nset friend-posting-probability 1.0\nbaseline-visualization\nsetup
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
1160
436
1215
469
A2
baseline-settings\nset new-info-mode \"individual\"\nset friend-posting-probability 0.5\nbaseline-visualization\nsetup
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
1100
472
1155
505
A3
baseline-settings\nset new-info-mode \"individual\"\nset friend-posting-probability 0.2\nbaseline-visualization\nsetup
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
1160
472
1215
505
A4
baseline-settings\nset new-info-mode \"individual\"\nset friend-posting-probability 0.05\nbaseline-visualization\nsetup
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
1100
521
1155
554
B1
baseline-settings\nset new-info-mode \"individual\"\nset influencer-dominance 0.1\nbaseline-visualization\nsetup
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
1160
521
1215
554
B2
baseline-settings\nset new-info-mode \"select close infobits\"\nset influencer-dominance 0.1\nbaseline-visualization\nsetup
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
1100
570
1155
603
C1
baseline-settings\nset new-info-mode \"select close infobits\"\nset feed-system true\nset like-mode \"likes\"\nbaseline-visualization\nsetup
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
1160
570
1215
603
C2
baseline-settings\nset new-info-mode \"select close infobits\"\nset feed-system true\nset like-mode \"likes and dislikes\"\nbaseline-visualization\nsetup
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
1100
619
1155
652
D1
baseline-settings\nset new-info-mode \"select nearish infobits\"\nbaseline-visualization\nsetup
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
1160
619
1215
652
D2
baseline-settings\nset new-info-mode \"select nearish infobits\"\nset friend-posting-probability 0.2\nset influencer-dominance 0.1\nbaseline-visualization\nsetup
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
1100
668
1155
701
E1
baseline-settings\nset new-info-mode \"balanced with distant\"\nbaseline-visualization\nsetup
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
1160
668
1215
701
E2
baseline-settings\nset new-info-mode \"balanced with distant\"\nset friend-posting-probability 0.2\nset influencer-dominance 0.1\nbaseline-visualization\nsetup
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
1100
704
1155
737
E3
baseline-settings\nset new-info-mode \"balanced with neutral\"\nbaseline-visualization\nsetup
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
1160
704
1215
737
E4
baseline-settings\nset new-info-mode \"balanced with neutral\"\nset friend-posting-probability 0.2\nset influencer-dominance 0.1\nbaseline-visualization\nsetup
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
14
716
164
734
5) Influencers
12
0.0
1

SLIDER
10
735
252
768
influencer-dominance
influencer-dominance
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
10
771
252
804
influencer-share
influencer-share
0
1
0.01
0.001
1
NIL
HORIZONTAL

TEXTBOX
14
815
164
833
6) Feed
12
0.0
1

SLIDER
10
835
152
868
feed-size
feed-size
1
10
5.0
1
1
NIL
HORIZONTAL

SWITCH
155
835
252
868
feed-system
feed-system
1
1
-1000

SLIDER
10
871
152
904
rewatch-rate
rewatch-rate
0
1
0.098
0.001
1
NIL
HORIZONTAL

SWITCH
155
871
252
904
less-rewatch
less-rewatch
1
1
-1000

TEXTBOX
14
915
164
938
7) Likes
12
0.0
1

CHOOSER
10
941
252
986
like-mode
like-mode
"views" "likes" "likes and dislikes"
1

SLIDER
10
989
252
1022
like-rate
like-rate
0
1
0.6
0.001
1
NIL
HORIZONTAL

SLIDER
10
1025
252
1058
dislike-rate
dislike-rate
0
1
0.1
0.001
1
NIL
HORIZONTAL

@#$#@#$#@
# Triple Filter Bubble Model

This is the web version of the model which is reduced in complexity and features.

**Please also check out the offline model at: [https://github.com/LockedInTheSkage/BroadBubble](https://github.com/LockedInTheSkage/BroadBubble)**

## WHAT IS IT?

This model is the basis of the paper

**Broadening the Bubble: Technological Countermeasures to Isolation in an Agent-based Simulation of Social Media**

by _Aksel Saugestad, Skage Klingstedt Reistad, Vira Antonova, Ovidiu Victor Tătar, Md. Anwarul Hasan_

It is itsself an extension of the model provided by and discussed in the paper

**The triple filter bubble: Using agent-based modeling to test a meta-theoretical framework for the emergence of filter bubbles and echo chambers**

by _Daniel Geschke, Jan Lorenz, Peter Holtz_

Some aspects of our extensions are explained in our research paper mentioned above.
**All further details described here are from the original paper! We updated the information, but most of the text was written by Geschke et al. and not by us.**

Geschke et al. call it the **triple filter bubble model** because information needs to pass three filters to reach our memories: Bits of information come to our attention through technology (including mass media, and filter algorithms), through our social network, and they have to pass the cognitive filters in our brains. This model is to test via simulations how these filters interact when information is attitudinally loaded and what this implies for the emerging distribution of attitudes in the population, e.g., concerning filter bubbles and echo chambers.

**Model synopsis**: Several individuals (represented by colored circles, called _guys_ in the following) position themselves in a two-dimensional attitude space based on attitudinal info-bits (gray dots) they hold in memory (gray info-links). Guys repeatedly receive new information with differing attitudinal messages from different sources. The sources of new information can be

   - individual discovery,
   - central announcement (representing mass media), or
   - personalized recommendations, which either
     - fits the attitudes of the guy,
     - challenges them,
     - fits the attitudes, but not perfectly,
     - fits the attitudes 70% of the time and challenges them 30% of the time, or
     - fits the attitudes 70% of the time and proposes normally distributed information them 30% of the time.

Guys also receive posted information from their friends (yellow friend links) through a social network (social media channel).
Further on, influencers can play a role and post information to a share of the whole network.

Guys integrate the information they receive through cognitive processes: They integrate a particular bit of information more likely when the distance of its attitudinal message to their attitude is below the latitude of acceptance. That means that it is unlikely that they integrate information that does not fit their pre-existing attitudes. Guys have a limited memory and can only integrate a certain amount of information. When memory is full, guys forget bits of information to integrate new ones. These processes lead to repositioning of guys in the attitudinal space according to the average information they consequently hold in their memory.

## HOW IT WORKS

### World

The world represents a square two-dimensional *attitude space* with the origin (neutral attitude on both dimensions) at its center. Attitudes can range between -1 and +1 in both attitude dimensions.


### Entities and Initial Conditions (Setup)

**_guys_**. On setup, **numguys** guys are created with random positions in the attitude space (uniformly distributed). The number of guys stays constant even when birth and death happen. Guys are characterized by their attitudinal position in the two-dimensional attitude space which can change over time, and by the label of their friendship community which stays constant throughout its lifetime.
**_friend_** links are undirected links between guys which represent the social network between them. The number of friend-links is held constant after initialization even when social network dynamics are switched on.
**_infobits_** appear and vanish as points in the same attitudinal space where guys position themselves. They represent news items from mass media, recommended from online media providers, or produced by guys, stripped down to their attitudinal message.
**_infolinks_** are undirected links between guys and info-bits, which represent the fact that the guy holds a particular info-bit in memory. Info-links create a bipartite network between guys and info-bits. Thus, they also create indirect connections between guys who link to (i.e., know) the same info-bit. Such a link between guys will be called **_infosharer_** link.

On setup, the social network of friend-links is created between guys characterized by the expected number of friends **numfriends**, the parameter **fraction-inter**, the **network-type**, and the parameter **numgroups** (only effective when network-type is "groups"). For the network-type "groups" a random networks with **numgroups** groups is constructed randomly but such that on average a fraction of **fraction-inter** of each guy are to guys from the same group and the rest to guys from other groups. For the case numgroups=1 this equals a classical random graph where a link between any two guys exists with the probability numfriends/numguys. For the network-type "watts-strogatz", NetLogos Watts-Strogatz function is used with **numfriends**/2 ring neighbors on both sides and a random rewire-probability of fraction-inter.

### Core mechanism: Integration of new info-bits (creating and infolink)

The core cognitive process of guys is the integration of new information. Over time guys perceive new info-bits. They integrate such an info-bit into memory (= (create an infolink) based on its position in the attitude space. Integration is a binary random event based on the integration-probability, which is a function of the attitude distance between the guy and the info-bit _d_. An info-bit is integrated with certainty if the attitudinal position of the info-bit coincides with the attitudinal position of the guy (_d_=0). The probability of integrating an info-bit decreases with _d_ (cf. Fisher & Lubin 1958, Abelson 1964, Fishbein & Ajzen 1975). This means that information fitting the guy's average pre-existing attitudes is more likely to be integrated. The decrease is shaped by two parameters, the **acceptance-latitude** _D_ (Sherif & Hovland, 1961), and the **acceptance-sharpness** δ which specifies how sharply the integration probability drops from one to zero around the latitude of acceptance. We use the following functional form

_f_(_d_;_D_,δ) = _D_<sup>δ</sup>/(_d_<sup>δ</sup>+_D_<sup>δ</sup>)

This formula follows the formalization of the Social Judgment Theory of Hunter, Danes, and Cohen (1984). However, they only dealt with the case of δ=2 and did not take into consideration a sharper decline around the latitude of acceptance. In the limit δ to infinity, this coincides with the bounded confidence model (Deffuant, Neau, Amblard, & Weisbuch, 2000; Krause, 2000). At _d_=_D_ the integration probability is 0.5. At the limit of very large sharpness parameters, probabilistic remembering becomes deterministic. In this case, info-bits are integrated with certainty if the distance is less than D, and are rejected otherwise.

Guys can only have infolinks up to a maximum number of **memory** info-bits. When a guy has a full memory and wants to integrate a new info-bit, a random info-link is dropped (i.e., forgotten) before the new info-bit is integrated. After the integration of a new info-bit, the guy readjusts its attitudinal position to the average attitude of the info-bits she holds in memory, which follows Anderson’s (1971) integration theory.

### Model dynamics (Go)

In each tick the following events take place:

1) _New info-bits._ There are seven **new-info-mode**'s for the creation of new info-bits.

In the _individual_ mode, each guy creates one info-bit at a random position and tries to integrate it. This mode represents individual discovery of new information.

In the _central_ mode, one info-bit is created at random in the attitude space and every guy tries to integrate this info-bit. This represents mass media input from one central, unbiased channel (one-to-many communication).

In the five remaining modes, a new random info-bit is created and presented to each guy analogously to the _individual_ mode until the total number of info-bits is equal to the number of guys. This can take some ticks, because info-bits are not always integrated by guys. If the number of info-bits is equal to the number of guys, each guy is presented a random existing info-bit which is inside (in the mode _select close info-bits_) or outside (in the mode _select distant info-bits_) a radius of size acceptance-latitude around the guy's attitude position. This represents the use of a recommendation algorithm that aims to present info-bits which the receiver will integrate with a probability higher than 0.5 (_select close info-bits_) or, respectively, an info-bit which confronts the guy with very different (but perhaps interesting) information. The remaining three modes are a variation of these schemes, selecting information which does not perfectly match the guys lattitude of acceptance (_select nearish info-bits_), or they present close information most of the time (mimicing what a recommendation algorithm would prefer to do), and either distant (`balanced with distant`) or normally distributed information (`balanced with neutral`) occasionally.
Each guy only receives one additional info-bits per tick.

2) _Guys post info-bits to their friends._ All guys, one after the other in a random order, select a random info-bit from their memory and post it to each friend in their social network with a probability of **friend-posting-probability**. The randomly selected friends try to integrate the new info-bit, which represents the propagation of information through social media.
Each guy receives on average _numfriends × friend-posting-probability_ additional info-bits per tick.

3) _Influencers post info-bits to a fraction of the population._ Influencers post regularily as other guys do, but instead of posting to their friends, they post to a randomly selected share of **influencer-dominance** of all guys.
Each guy receives on average _numguys × influencer-share × influencer-dominance_ additional info-bits per tick.

4) _Turn-over and refriending_  Each guy dies with probability **birth-death-probability** and is replaced by a new guy in a random position in the attitude space. Friend-links are inherited from the old guy created for the new guy such that the characteristics of the social network are preserved. New guys start with no info-links.

Afterward, each friend-link is subject to die with the probability **refriend-probability**. If a friendship is selected for potential death it stays alive based on a probabilistic event analogous to the integration of info-bits. Thus, friendships are more likely to vanish when the attitudinal distance of the friends is large, whereas friends with similar average attitudes are more likely to remain friends. When a friend-link dies, one randomly selected end of this link forms a new friend-link to a randomly selected friend of a friend with whom she is not friends yet. This re-friend mechanism preserves the number of friendships.

Finally, each infobit which is not held in any guy's memory is removed.
These steps are repeated in every tick.

## THINGS TO NOTICE AND TRY

Notice how clusters of guys emerge and if these clusters remain connected through links of info sharing or links of friendships. Use the visualization parameters to observe some of these in detail. You can switch the visualization of links on and off, as well as the visualization of guys and infobits. You can also switch everything of and check the frequencies of guys and infobits in the world through patch colors.

Check in the output measures which mean distance is largest under what conditions:

  - entropy of the guys (as a measure of their overall spread)
  - mean distance to infosharer
  - mean distance to friends
  - mean distance to infobits (primarily determined by acceptance-latitude)

Speed up computation by lowering the number of times the plots are updated!

Test the **scenario setups** from both papers included in the model.

In all scenarios the birth-death-probability is 0, the acceptance sharpness is 20 (quite sharp).

You can check that the number of groups in the friends network or its network-type to have only limited effect.


## CREDITS AND ACKNOWLEDGMENTS
Programmed by Jan Lorenz, extended by Skage Klingstedt Reistad and Ovidiu Victor Tătar

Hosted [https://github.com/LockedInTheSkage/BroadBubble](https://github.com/LockedInTheSkage/BroadBubble)

Original Model [https://github.com/janlorenz/TripleFilterBubble](https://github.com/janlorenz/TripleFilterBubble)
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
