# Disco Infernal

Tight version: One night. One club. Ghosts possess dancers. You dodge, save the DJ, find MJ's suit and moonwalk before midnight. 6-ish rooms. Survive.


## Proposal

I was thinking of something in the style of the 1984 Ghostbusters game (https://www.c64-wiki.com/wiki/Ghostbusters), or  Ghosts 'n' Goblins (https://en.wikipedia.org/wiki/Ghosts_'n_Goblins_(video_game)), or Hugo's House of Horrors (https://en.wikipedia.org/wiki/Hugo's_House_of_Horrors).  Horror themed but not strictly horror.


My idea is a bit of a pastiche.  In the 1970's — a group of mad and evil cultists made contact with an entity from the the wicked world of the Disco Infernal.  They built a nightclub on the site of their ritual.  The nightclub was complete and the hour of the great conjunction was near.  Club-goers came and started dancing, and as they were dancing — they were taken over by spirit of disco.  Had the night completed as planned — all the club goers would have been possessed and they would have gone out into the night as Disco Demons, and conquered the world.  The Disco Infernal would reign supreme.  They were only stopped by the timely arrival of Michael Jackson.  The club has lain derelict since then.


Jump to the present — the player has inherited the club from a crazy old uncle he didn't know he had.  The will stipulates he can keep the club but only if he opens it and runs by a specific date — "tonight".  It's another Great Conjunction.  He opens the club and is running things.  As customers arrive and start to dance — ghostly disco dancers begin to appear.  They start possessing the club-goers.  The player has to avoid possession, keep the ghosts from possessing the DJ, and solve the mystery and save the world.  Or the Disco Infernal will conquer all.


Alternative Saviour or minor optional Easter Egg:  The janitor is actually Elvis.  He faked his death so he could come here and guard the portal.  He was here back in the 70’s, and he never left.  He even sleeps here.  One problem — he’s forgotten everything.  And his hips are killing him.


## Specs

Graphics:  In the early 1980s – video graphics were CGA and EGA (320 x 200) with 640 colours.  In 1987, a new standard was released — VGA.  This was 640 x 480 with 256 colours.  With 32x32 pixel sprites and a 320 x 240 viewport — our game is slap-bang in this era.

https://itch.io/jam/dos-vgaadlib-jam-2026-take-2

https://www.youtube.com/watch?v=cQD9EYX3bfY

https://itch.io/jam/cga-jam-2024

https://itch.io/jam/cga-jam


Sound:  In 1987, Adlib released a new sound card powered by the Yamaha YM3812 (OPL2) chip.  This introduced multi-channel frequency modulation (FM) to the games industry.  Sound cards ran ahead of graphics cards in sophistication.

https://www.youtube.com/watch?v=QloftqK2o-I

https://www.google.com/search?client=firefox-b-d&q=AdLib+OPL2+(YM3812).+1987.+FM+synthesis.+The+sound+of+DOS+disco.#fpstate=ive&vld=cid:d4e27343,vid:ViBIGeVGgkM,st:0


Time:  As this is a 1-week game jam, I propose a 15 minute game.  The club opens at 8pm.  The climax happens at 12am.  The world runs at 16x speed.  1 game minute every 3.75 seconds.


Layout:  The club contains the following areas — the main floor which has a bar with some barstools, tables and chairs.  The dance floor which has a DJ booth and an old dusty disco ball.  Doors to the Ladies and Gents toilets are on the back wall — we don’t need to animate those areas.  A third door in the middle — next to the DJ booth — opens onto the stairwell.

Upstairs — the Office is to the right, and the owners flat is to the left.

Downstairs — the basement is divided into a boiler room to the right, and the cellar to the left.


## Characters

### The Player

- Inherited the club from a crazy old uncle he didn’t know he had.
- The will states the club has to be open on a specific date: October 6 2026.
- Has sunk his life-savings into the club — All £9.99.
- Can see ghosts — the club goers don’t seem worried.  Maybe they can’t see them.
- Has a resistance meter vs possession.  Drained by ghosts or Mr Boogie-Woogie.  Ticks up when resting.  Replenished from bar or drinks cabinet in the office.
### Mr Boogie-Woogie

- Is the BBEG
- Lurks in the basement
- Drained by acting.  Rest to recharge.
- Brings boxes of disco records from the basement up to the DJ
- More powerful and active as it gets near midnight
- More active and powerful when the DJ is playing Disco
- More active when there are more ghosts and more possessed dancers
### The DJ

- Stands in the DJ booth.
- Plays whatever record he is brought
- Comments on the crowd and the vibe
### Raul — the barman

- His Dad used to work here back in the day.  Told him tales about this place.
- Serves drinks.
- Gives info.
### Vince Everett — the janitor

- Lurks in the boiler room
- Has a mop and bucket
- Looks like Elvis.  Might even be Elvis
- Has been here “forever”
- Gives info
- Can make Holy Water
### Customers / Dancers

- Move between the dance floor, bar, and rest rooms
- Dance
- Buy and consume drinks
- Block movement
- Can be possessed by ghosts --> becomes possessed dancer
- Can be cured with Holy Water when rock is playing
### Ghosts

- Appear when Disco is playing
- Fade when Disco stops (on a timer)
- Haunt dance floor and disco ball
- Can Possess dancers when Disco is playing
- Banished by Holy Water when Rock is playing
### Possessed Dancers

- Dance
- Block movement
- Demand Disco when Disco is not playing
- Can be cured with holy water when Rock is playing

## Items

- Holy water
- Drinks
- Boxes of records
- Holy Water
- A clock – advances 1 min every 3.75 seconds — from 8pm to 12am (midnight)


## Collision Layers

- Layer 1	Physical Object
- Layer 2	Object that block talking
- Layer 4	Entities that can talk to the player

## Interface Buttons and Keys

- Movement	WASD
- Talking	T
- Aiming	Right-Click + mouse pointer to aim
- Inventory	I
- Drink	E
- Spray	Left-Click (you must aim first)

## Mechanics

- Player Actions: Player has the option to drink and spray, each action takes 0.5s to complete. While drinking, you can’t spray and vice-versa. Move speed is reduced to 0.1 x normal speed during these actions.
- Mr Boogie-Woogie Energy & Latency: Operates on an energy pool (capacity: 25, tracked on HUD). Starts the night latent in the basement with 15 filled energy. While latent and invisible, recharges every game minute (3.75s) at: 1 (base) + 1 per elapsed hour past 8pm (+3 when Disco plays, +1 per possessed dancer).
- Mr Boogie-Woogie Manifestation & Movement: Reaching 25/25 energy triggers appearance animation, resets position to basement origin, enables collision, and manifests in the club. Waits 1 game minute before manifestation cost starts draining. Marches towards the DJ booth along an A* path consuming 5 energy per minute.
- Mr Boogie-Woogie Disappearance & Reset: When energy drops below 1, plays fade animation, disables collision, turns invisible, and returns to basement origin to hibernate and resume recharging.
- Mr Boogie-Woogie Crowd Shoving: Entities in the "pushable" group (Player, Customers/Dancers) cannot physically block Mr Boogie-Woogie. Outward force (push_force: 60) continuously pushes them aside unhindered.
- Mr Boogie-Woogie Ghost Summoning: While active in NORMAL state, Boogie has a random chance per frame to summon a ghost if energy >= 5. Consumes 5 energy per summon. Process takes ~1.0s: halts movement, plays summon animation, expands summon aura (0.7s expand, 0.3s shrink), spawns a ghost 30 units away in a random direction, then resumes normal movement.
- Ghost Materialization & Appearance: Spawns latent and materializes via shader dissolve effect over 1.0 second. Movement and actions are locked during this appearance phase.
- Ghost Targeting & Retargeting: After materializing, acquires a random unpossessed target (Player or Dancer) registered in GameManager. Pathfinds via A* recalculated every 0.5s. If current target becomes possessed or is being possessed by another ghost, immediately retargets to the next available unpossessed dancer.
- Dancer Possession Transition: Triggered when a ghost reaches within 10 units of a dancer and channels for 2.0 seconds: (1) Rapid Flashing: Alternates normal and possessed sprites with accelerating frequency (interval decreases from 0.28s to 0.03s via Quad In easing). (2) Shaking: During the final 40% of duration (last 0.8s), sprite jitters with increasing intensity (up to 2.5px offset). (3) Completion: Dancer permanently turns into a Possessed Dancer. Aborts if interrupted or ghost leaves range.
## Architecture

- Mr Boogie-Woogie State Machine: Implemented as an explicit finite state machine (FSM) with 5 states: (1) HIBERNATE: Invisible in basement, collision disabled, recharges energy on game minute tick. (2) APPEAR: Plays appear anim, resets global position to basement origin, enables collision, starts 1-minute grace timer. (3) NORMAL: 100 speed A* navigation to DJ booth, continuous crowd shove (force: 60), rolls per-frame summon check. (4) SUMMON: Pauses movement, plays summon anim, runs 1.0s aura Tween (0.7s expand / 0.3s shrink), spawns Ghost scene at 30 unit offset, deducts 5 energy, returns to NORMAL. (5) DISAPPEAR: Plays fade anim, disables collision, sets visibility to false, transitions back to HIBERNATE.
- Ghost State Machine: Governed by a 4-state FSM: (1) APPEAR: 1.0s CanvasItem shader tween (progress 0.0 to 1.0), movement locked. (2) NORMAL: Dynamic A* pathfinding (interval: 0.5s) chasing target at 40 speed, validates target state and retargets if target is claimed. (3) POSSESS: Triggered when within 10 units of target, channels for 2.0s; aborts to NORMAL if target moves out of range. (4) DISAPPEAR: Triggered when hit by holy water during Rock music, plays banish effect and frees node.
- Dancer / NPC State Machine: Governed by a 3-state FSM: (1) NORMAL: Dances to active music, registers with GameManager target pool. (2) BEING_POSSESSED: 2.0s transition state running Quad In sprite sheet toggle (0.28s to 0.03s) and late-stage offset shake (progress > 0.6, jitter up to 2.5px). (3) POSSESSED: Locks to possessed sprite sheet, demands Disco music, obstructs player navigation.
- Pathfinding Architecture: Custom 2D Grid A* (PathfindingManager, PathfindingGridData). Static routes (Boogie to DJ) are precalculated once upon scene load. Dynamic targets (Ghosts chasing moving dancers/player) utilize throttled 0.5s replanning intervals with checkpoint distance tracking (min_distance_for_index_change: 1.5).
- VFX & Tweening Pipeline: CanvasItem shader parameters control ghost dissolve/materialize over normalized progress floats. SceneTreeTweens handle animations (aura expansion/shrink, sprite jitter, possession flash easing) without runtime physics overhead.
- Global State Coordination: Centralized GameManager singleton handles entity registration (ghost_targets pool), game clock broadcasts (on_game_time_changed signal), and HUD synchronization.