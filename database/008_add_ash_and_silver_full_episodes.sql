-- 008_add_ash_and_silver_full_episodes.sql
-- Adds the complete Season 1 prose drafts to the existing Ash and Silver episodes.
-- Each episode is between 850 and 1,000 words.
-- Safe to rerun: it replaces script_text and word_count, but does not alter
-- existing audio URLs, artwork, publication status or recorded audio duration.

BEGIN;

DO $check$
DECLARE
    v_episode_count integer;
BEGIN
    SELECT COUNT(*)
    INTO v_episode_count
    FROM public.episodes AS e
    INNER JOIN public.stories AS s
        ON s.id = e.story_id
    WHERE s.slug = 'ash-and-silver'
      AND e.season_number = 1
      AND e.episode_number BETWEEN 1 AND 10;

    IF v_episode_count <> 10 THEN
        RAISE EXCEPTION
            'Expected 10 Ash and Silver Season 1 episodes, but found %.',
            v_episode_count;
    END IF;
END
$check$;

WITH episode_scripts
(
    episode_number,
    script_text,
    word_count
)
AS
(
    VALUES
        (1, $ep01$
The clock on Elara's workbench had lied for thirty-seven years.

Its painted moon rose at noon, its silver stars appeared before sunset, and every third hour a tiny brass shepherd stepped through the wrong door. The owner had called it temperamental. Elara called it honest.

"It is telling us exactly what happened," she said.

Her father looked up from the tall case clock beside the window. "Is it?"

"The moon wheel was replaced. See the teeth? Too fine for the original gear. Someone forced a clever part into an older mechanism and hoped the rest would forgive them."

"And will it?"

"Mechanisms are less forgiving than people."

Her father smiled. "You have not met enough people."

Elara bent over the open clock. She loosened one screw, shifted the replacement wheel half a tooth, and reset the spring. The moon crossed the painted sky. The shepherd marched through the correct door.

Her father stared at the clock, then at the row of untouched repairs waiting behind her.

"That was meant to occupy you until midday."

"It did."

"The market bell rang nine less than an hour ago."

Elara closed the case. "Then I have gained a morning."

She had always gained mornings. Clockwork came easily to her, which was both a gift and a problem. Her father worked steadily from sunrise until the lamps were lit, supporting the family one careful repair at a time. Elara finished her share too quickly, and empty hours were dangerous things in the hands of a curious young woman.

She left the workshop with a parcel for a customer and her lock picks hidden inside her sleeve.

The lower market rang with sellers calling prices and children weaving beneath carts. Elara delivered the clock to a spice seller, accepted payment, and lingered beside a tray of copper buttons.

A young noble stood at the fruit stall nearby.

Elara noticed him because he looked out of place without looking uncomfortable. His coat was well cut but unadorned, his boots dusty from walking rather than riding. When the seller named a price, he paid it without bargaining. When a servant reached for the basket, he took one handle himself.

Then an old woman dropped a sack of onions across the stones.

Several people stepped around her.

The noble crouched and gathered the onions. No announcement. No grand smile. He simply returned the sack, listened to her thanks, and moved on.

Elara watched him for another moment.

"Another noble," she murmured.

Unusual, perhaps. Not her concern.

At the edge of the market, a woman in a dark green hood waited beside the public fountain. She handed Elara a folded strip of paper without greeting.

Merchant Veyran. Upper west house. Second-floor study. One sealed letter in the left drawer. Blue wax. Deliver unopened.

The payment was generous. The lock described below it was better.

Elara burned the note in a brazier behind the baker's stall and spent the rest of her stolen morning studying Merchant Veyran's house.

By sunset she knew the guard changed at the rear gate three minutes before the watch bell. She knew the kitchen chimney smoked heavily after supper. She knew the eastern drainpipe had been replaced but the western one still carried a person's weight. She knew a dog slept in the courtyard and woke only when the stable door creaked.

At midnight, she climbed the western wall.

The study window had three locks: one visible, one concealed beneath the sill, and one designed to trap the impatient. Elara smiled.

When she was ten, she had believed locks existed to keep people out. Her father had shown her otherwise.

A lock was a conversation between the maker and the person holding the key. Every pin asked a question. Every spring expected an answer.

Elara slid a thin strip of silvered steel into the keyway and listened through her fingertips.

The first pin was worn. The second had been replaced. The third caught too sharply, a false set intended to hold the cylinder if too much pressure was applied. She eased back, lifted again, and felt the mechanism surrender.

Inside, the room smelled of wax, old paper, and expensive wood oil.

She crossed directly to the desk. The left drawer carried another lock, simpler than the window but recently scratched. Someone had opened it in haste.

Elara stopped smiling.

She picked it anyway.

The drawer was empty.

Not searched. Not disturbed. Empty.

A clean rectangle in the dust showed where the letter had rested. A flake of blue wax clung to the corner. Beside it lay a streak of fine grey ash.

Someone had reached the study before her.

Elara examined the window from inside. No fresh marks except her own. The door lock was untouched. The fireplace grate, however, sat one finger's width crooked.

She knelt and found a narrow catch hidden beneath the stone lip. It released a panel no servant would have known existed. Behind it, a cramped stair descended into darkness.

The missing letter suddenly mattered far more than the job.

Elara took one step down.

A faint line of silver glimmered on the wall, not paint or metal leaf but something embedded in the stone. It curved around a symbol made of three interlocking arcs and a narrow shape like a folded wing.

She touched it.

The stone was cold.

Somewhere below, a mechanism clicked.

Not loudly. Not enough to wake the house.

Just one patient sound, like a clock beginning to count after a very long silence.

Elara withdrew her hand.

Then she smiled.

The letter was gone. Her payment was probably gone with it. Someone else had entered a room that should have been impossible to enter and left by a stair that should not have existed.

For the first time all day, Elara had found something difficult.

She closed the hidden panel, relocked the drawer, and left the study exactly as she had found it.

All except for the ash on her fingertip.

That, she carried home.
$ep01$, 1000),
        (2, $ep02$
Elara returned to Merchant Veyran's house the following afternoon through the front door.

She wore a work apron and presented the steward with an appointment token borrowed from a clockmaker who disliked Veyran.

"The west hall clock loses seven minutes each day," the steward said. "Master Veyran wants it corrected before his guests arrive."

"Then it has been losing seven minutes for longer than he has noticed," Elara replied.

The steward frowned, unsure whether he had been insulted, and led her inside.

The great clock stood opposite the staircase. Elara opened its case and began removing the dial while her attention moved through the house. Three guards. Two servants polishing silver. One clerk carrying ledgers from Veyran's study to a downstairs office.

No sign that the theft had been discovered.

That meant Veyran either did not know the letter was missing or did not wish anyone to know.

Elara adjusted the clock in twelve minutes, then deliberately misaligned the strike train so it would chime thirteen times at noon. The steward hurried away to complain. She slipped upstairs.

The study door had a new strip of wax across the keyhole. Not a seal - a test. Anyone inserting a key would break it.

Elara crouched.

Her father had given her the first lesson years ago, when she had dismantled a discarded lock simply because the gears in a clock had stopped being interesting.

"Why is this easier?" she had asked.

He had taken the lock from her hand and turned it beneath the lamp.

"It is not easier. It is only smaller."

"But I can feel where the pieces move."

"Then stop thinking of it as a door." He had pointed to a scratch beside the latch. "What does that tell you?"

"Someone misses the keyway when they are tired."

"And this?"

"The bolt drags against the frame."

"And this?"

She had studied the dark grease around one screw. "It was opened recently."

Her father had nodded. "Every mechanism tells you a story. The lock is only honest enough to leave the words where you can see them."

Now Elara studied Veyran's study door.

The wax was unbroken, but the lower hinge had fresh oil. The door had been removed from its frame after she left.

Someone had searched the room without using the lock.

She slid a thin mirror beneath the gap. The study was empty. A new iron bar crossed the hidden fireplace panel from the inside. Veyran knew about the stair now.

Elara returned downstairs before the steward found her. As she passed the temporary office, she glimpsed the clerk stacking documents into three piles.

Blue wax.

Green ribbon.

Black cord.

The missing letter had not been alone.

She left the house through the front entrance just as the west hall clock struck thirteen. While servants shouted, Elara crossed the street and entered a narrow alley.

A voice behind her said, "That was an unusual repair."

She did not turn.

Footsteps followed at an even pace. Not a guard's heavy stride. Someone younger, trained, and trying not to sound hurried.

Elara passed a laundry yard, ducked beneath a row of wet sheets, and changed direction. The footsteps changed with her.

At the alley's end she glanced into a glassmaker's window.

The young noble from the market appeared in the reflection.

He was alone.

Interesting.

She turned into a courtyard with only one visible exit. He entered two breaths later and found her standing beside a locked gate.

"Clockmaker," he said.

"Noble."

His eyes moved to her repair box. "The steward sent men looking for you."

"Then the clock must be keeping time again."

"It struck thirteen."

"Time is complicated."

He stepped closer. "You were upstairs."

"So were several stairs."

His mouth almost twitched. "Merchant Veyran has reported a theft."

That was useful. "Has he?"

"A letter."

"Then perhaps he should buy a better desk."

The noble's gaze sharpened. "Who are you?"

Elara glanced at the gate behind her. Tall iron bars. New padlock. Soft mortar around the left hinge.

"Someone late for supper."

He moved to block the alley.

Competent. He had noticed the gate too.

Elara dropped her repair box.

The lid sprang open, spilling gears and springs across the stones. The noble looked down for less than a heartbeat, but a heartbeat was enough.

Elara drove one metal pick into the soft mortar beside the hinge pin. She had loosened it while he spoke. The gate sagged inward. She slipped through the gap, pulled the pin free, and let the iron frame settle behind her.

The noble caught the bars before they struck the ground.

Strong as well as observant.

"What is your name?" he called.

Elara picked up the loose hinge pin and weighed it in her hand.

"Ask the clock."

She tossed it onto the stones and disappeared into the crowd beyond.

By evening, she knew his name.

Cedric.

Not an heir, but close enough to power that merchants welcomed his questions. He had volunteered to help investigate Veyran's stolen letter after seeing unfamiliar men leave the merchant's district before dawn.

Elara sat on the roof opposite Veyran's house and considered the problem.

Cedric believed he was following a thief.

Veyran believed one letter had been stolen.

The locks told a different story.

Someone had entered through the hidden stair, taken at least three related documents, returned after Elara's visit, and removed the study door rather than risk leaving marks on the wax.

Not a reckless burglar.

Not an ordinary spy.

Someone who knew exactly what to take and exactly which evidence mattered.

Below, Veyran's clerk carried a box of papers into a waiting carriage. A small fragment of green ribbon protruded beneath the lid.

Elara rose.

The carriage rolled east.

Cedric was still asking who she was.

The better question was who had stolen the other two documents - and why Merchant Veyran wanted the city to believe only one existed.
$ep02$, 987),
        (3, $ep03$
By the third day, the city had given Elara a name she had not chosen.

The Silver Fox.

A printer's apprentice had seen a grey-cloaked figure leap from a warehouse roof while Cedric shouted below. By noon, a tavern singer had given Elara silver hair, six knives, and a trained fox.

Her father read the handbill over tea.

"Apparently," he said, "the Silver Fox can walk through walls."

"Useful talent."

"And charm locks open by whispering to them."

"Less useful. Locks are terrible conversationalists."

He lowered the paper. "You have been out late."

"The city is noisy."

"The city has always been noisy."

Elara took another piece of toast.

Her father watched her for a long moment, then returned to the handbill. "The fox also leaves a silver mark at every theft."

That part was new.

By sunset, Elara had made one.

She cut a fox no larger than a thumbnail from a broken watch plate and tucked it into her sleeve. If the city insisted on telling stories about her, she might as well edit them.

The carriage carrying Veyran's documents had gone to an old counting house near the river. Elara spent the day mapping its entrances. Cedric spent the day mapping her.

He placed guards on the roof and canal stairs and left the upper window unlatched, either careless or inviting.

Elara approved.

He was learning.

She entered through the floor.

A disused rain channel passed beneath the counting house. The iron grate had not moved in years, but rust was only a lock that had forgotten its key. Elara loosened the outer frame, crawled through the channel, and emerged beneath a storage room filled with empty account boxes.

Voices sounded beyond the door.

"Veyran should never have kept the copy," a man said.

A woman replied, "He kept everything. That is why he was useful."

"And the third piece?"

"Not here."

Elara moved closer.

The storage-room lock was cheap but loud. She inserted a tension tool, then paused. One pin had been filed shorter than the others. The lock had been altered to catch anyone who picked it in the normal order.

Someone expected thieves.

Elara smiled and worked backward.

The door opened without a sound.

Through the gap she saw two figures standing over a table. Both wore dark travelling coats. The woman held Veyran's blue-waxed letter. Beside it lay a strip of green ribbon wrapped around a narrow parchment and a black cord with nothing attached.

Three pieces.

The man placed the blue letter over a candle flame.

Elara needed the contents more than the paper.

She slipped into the corridor, reached a brass alarm bell fixed to the wall, and pulled the cord twice.

The counting house erupted.

Doors opened and clerks shouted about smoke. The two figures swept the documents into a leather case and ran.

Elara crossed the rafters, dropped behind them, cut the case strap, and caught it.

The woman spun with a knife.

Elara kicked the door shut between them.

Then someone on the other side caught it.

Cedric pushed through.

For one absurd moment, all four of them stared at one another.

"The Silver Fox," Cedric said.

The woman with the knife fled downstairs. Her companion followed.

Cedric moved after them.

Elara moved the other way.

He stopped.

So did she.

The case in her hand made the decision for him.

Cedric lunged.

Elara vaulted the banister, swung across the stairwell on a hanging chain, and reached the upper door ahead of him.

He had predicted the roof.

Two guards waited beside the chimney.

Elara changed direction before they saw her. She crossed the ridge tiles, slid beneath a drying rack, and jumped onto the roof of the neighbouring bathhouse.

Cedric followed.

He was faster and quieter than expected. Rather than shout, he watched her feet and learned which tiles she trusted.

Elara dropped into a courtyard and found the canal gate locked.

Cedric landed behind her.

"No loose hinges this time," he said.

"You noticed."

"I notice many things."

"Eventually."

She knelt at the gate's padlock.

Cedric approached slowly. "You cannot pick that before I reach you."

"No."

His expression shifted.

Elara did not touch the padlock. She removed the entire latch plate. The screws had been replaced recently, and the builder had used soft brass. She had loosened them during her earlier survey.

The gate opened.

Cedric caught her wrist as she passed.

Up close, Elara saw the effort beneath his calm. He had expected victory and found another question.

"Give me the case," he said.

"Ask nicely."

"Please give me the stolen case."

"Better."

She drove her heel against the gate. The loosened latch struck Cedric's forearm. His grip opened. Elara twisted free, slipped through, and kicked the gate shut.

Before running, she placed the tiny silver fox on the top rail.

Cedric looked at it, then at her.

"That is childish."

"Then stop losing to it."

She vanished down the canal steps.

Only when she reached an abandoned dye yard did she open the leather case.

The blue-waxed letter was inside, but the green-ribbon document was gone. The black cord remained attached to a small metal cylinder, no longer than her finger.

Elara turned it beneath the moonlight.

Its surface bore the same interlocking arcs she had seen beneath Veyran's fireplace.

One end held a narrow slot. Not a keyhole exactly. More like a missing piece of a machine.

Inside the case, someone had scratched a message into the leather:

BENEATH THE FIRST FOUNDATION.

Elara looked back toward the city.

The capital's oldest temples and courts stood on the hill above the river.

But foundations were not made to be seen.

She closed the case.

Behind her, Cedric found the silver fox and understood she had planned the gate.

In the dye yard, Elara understood something else.

The people who had taken Veyran's documents were not stealing secrets from the city.

They were looking for something beneath it.
$ep03$, 994),
        (4, $ep04$
Cedric stopped chasing Elara where she expected him to.

That worried her more than pursuit.

For two days, no guards appeared on her roofs and no patient noble waited outside the workshop.

Then, on the third night, every route closed at once.

Elara left the records hall with a copied foundation plan beneath her coat. A chain blocked the western jump, watchmen closed the southern stairs, and the eastern route ended at a repaired bell-tower door.

Cedric stood beside it.

"You are improving," Elara said.

"I had a good teacher."

She backed toward the parapet. Four storeys below, carts rattled through the lane. Cedric had replaced the loose tiles and removed her drain rope.

He had read her mechanism.

The realisation delighted her, although she did not show it.

"Give me the foundation plan," he said.

"You do not know that I have one."

"You visited the records hall three times this week. Tonight the archivist found a window open and one drawer disturbed."

"Careless archivist."

"The disturbed drawer contains maps of the oldest civic buildings."

"Then I hope nothing valuable is missing."

Cedric moved closer. "You are not stealing for money."

"That disappoints you?"

"It complicates you."

"People are not clocks."

"No," he said. "Clocks are easier."

Elara almost laughed.

Below them, the watch bell began to ring.

Once.

Twice.

Then without rhythm.

Alarm.

A line of orange light rose beyond the eastern warehouses.

Fire.

Cedric glanced toward it, but only briefly. "A distraction?"

"Not mine."

The flames grew too quickly. One warehouse roof caught, then the next. People shouted in the streets.

Elara smelled oil.

She also heard wheels.

A covered carriage raced toward the eastern gate against the crowd. Its rear axle struck a stone, revealing the cargo inside.

A black iron chest.

The records hall kept its sealed royal archives in a chest exactly like that.

Cedric saw her attention shift.

"What?" he asked.

"While you were arranging this excellent trap, did you ask why the archivist's night clerk went home early?"

His eyes narrowed.

"Or why the fire began beside the eastern watch post?"

The carriage turned onto Gate Street.

Cedric looked from Elara to the smoke.

"You expect me to believe someone is stealing the archives now."

"No. I expect you to continue arresting me while they do it."

He hesitated.

That was all she needed.

Elara ran toward the bell tower, jumped onto its stone frame, caught the bell rope, and swung outward.

The rope dropped her toward the lower roof.

Cedric seized the trailing end.

For one breath, Elara hung above the lane while he held her weight.

"You planned that?" he called.

"I hoped."

"That is not the same thing."

"It is when the alternative is falling."

She pulled a small knife from her sleeve and cut the rope below her hand.

Elara dropped onto a canvas awning and rolled into a vegetable cart.

The seller screamed.

"Apologies," Elara said, already running.

She reached Gate Street through alleys no carriage could enter. The gate stood open for fire crews, and the carriage carried an official seal.

A false one.

The wax crown leaned left. The true seal had a damaged right point.

She climbed a lamppost and leapt onto the carriage roof.

The driver swore and whipped the horses faster.

Elara slid to the rear and reached the chest through the curtain. Four locks: two ordinary, one warded, and one hiding a spring blade.

A story in iron.

The chest had been built to frighten thieves into rushing.

Elara listened.

Behind them, a horse thundered through the gate.

Cedric.

He had chosen the archive.

Good.

Elara opened the first lock. Then the third. The blade released harmlessly into an empty channel. She turned the second and felt the fourth loosen.

The chest opened.

Inside lay bundles of sealed records, a rolled map tied with green ribbon, and a stone disk marked with the interlocking arcs.

The same men from the counting house had not been fleeing the city.

They had been collecting the remaining pieces.

A crossbow bolt struck the carriage roof beside Elara's hand.

The woman from the counting house leaned from the front window with another bolt ready.

Elara grabbed the green-ribbon map and the stone disk.

Cedric drew alongside on horseback.

"Jump," he said.

"Still trying to catch me?"

"At present, I am trying to keep you alive."

The woman fired.

Elara jumped.

Cedric caught her badly. They nearly pulled each other from the saddle, but he kept the horse upright and turned into the gatehouse yard.

The carriage escaped into the dark road beyond the walls.

Guards closed the gate too late.

Cedric dismounted. Elara stepped away before he could take her arm again.

"You let them go," she said.

"I saved you."

"Questionable priority."

"You had the map."

Elara looked down. In the confusion, the green-ribbon roll had torn. Half remained in her hand. The other half lay somewhere beyond the gate.

Cedric saw the stone disk beneath her coat.

"So," he said, "you were telling the truth."

"I often do. People find it inconvenient."

The guards approached.

Cedric could still arrest her. He had witnesses, stolen records, and half the city watch within shouting distance.

Instead he turned toward them.

"The thieves escaped east," he called. "The woman has a crossbow. Seal the river road."

When he looked back, Elara was already moving toward the shadows.

"Fox," he said quietly.

She stopped.

"What was in Veyran's letter?"

"I do not know yet."

"Then we are both behind."

Elara considered him.

The game had changed. Cedric had built a trap good enough to catch her, then abandoned victory to follow the evidence.

Competent. Annoying. Possibly useful.

She tossed him the stone disk.

He caught it with both hands.

"That is not trust," she said.

"What is it?"

"A question."

She disappeared through the gatehouse workshop, leaving Cedric with the symbol.

For the first time since the market, he did not follow.
$ep04$, 995),
        (5, $ep05$
The stone disk did not belong in Cedric's hands.

Elara decided this before breakfast, reconsidered it while repairing a naval chronometer, and became certain when a uniformed messenger entered the workshop carrying a wrapped parcel.

"For the clockmaker's daughter," he said.

Her father looked over his spectacles. "Which one?"

The messenger blinked.

Elara took the parcel. Inside lay the disk, a folded copy of the records seal, and a note in Cedric's precise handwriting.

It does nothing. I assume that means I am holding it incorrectly.

Her father glanced at the stone. "A gear?"

"Perhaps."

"It has no teeth."

"Not all gears admit what they are."

He returned to the chronometer. Elara carried the disk to the rear bench and placed it beneath the magnifying lens.

The interlocking arcs were not carved decoration. Tiny differences in depth formed channels. The wing-shaped mark at the centre could rotate, although centuries of grit had fixed it in place.

Elara cleaned the grooves with a strand of horsehair.

Her father watched without appearing to.

"What story does it tell?" he asked.

"That someone wanted it mistaken for a symbol."

"And beneath that?"

She traced the outer ring. "It sat inside something larger. The edge is polished on one side and rough on the other. It turned, but only partway."

"Broken?"

"Interrupted."

He nodded, accepting the distinction.

Elara spent the day comparing the disk with old drawings stored beneath the workshop stairs. Her father collected diagrams not because they were rare, but because customers often brought repairs with missing parts. A drawing of an obsolete water clock could explain a spring in a traveller's compass. A mill gear might suggest the shape of a lost escapement.

Most papers were ordinary.

One was not.

It showed a circular mechanism discovered beneath a demolished bathhouse fifty years earlier. The draftsman had labelled it decorative stonework. Elara saw the same channels, the same three arcs, and a gap shaped exactly like the disk.

A note in the margin read: Removed after collapse. Remaining structure inaccessible beneath First Foundation wall.

First Foundation again.

She laid Cedric's half map beside the drawing. The torn edge aligned with an old drainage plan, but several passages ended against blank stone. One blank section curved in the same radius as the bathhouse mechanism.

Her father set a cup of tea beside her.

"You are doing the thing," he said.

"What thing?"

"The thing where you forget food because an object has offended you."

"It has not offended me."

"Then why are you glaring at it?"

"It is pretending to be incomplete."

He pulled up a stool.

When Elara was twelve, she had tried to repair a clock whose main wheel refused to turn. She had pressed harder until her father caught her wrist.

"Do not force it."

"It should move."

"That tells you what you want. Not what happened."

He had removed the dial and shown her an older repair hidden behind the plate. Someone had shortened the axle, shifting the pressure onto the wrong wheel.

"The mechanism is not resisting you," he had said. "It is carrying a mistake."

Now Elara looked again at the stone disk.

It was not the missing part.

It was carrying one.

She warmed the disk over a lamp, then cooled its centre with a damp cloth. Different materials contracted at different rates. A thin silver insert rose from the wing-shaped mark.

Her father leaned closer.

"That was hidden well."

"It was hidden from people who thought stone was stone."

Elara lifted the insert. Beneath it lay a narrow spindle and three tiny notches. When she turned the spindle, the channels in the disk aligned into a map.

Not streets.

Levels.

The capital drawn downward.

A route began beneath the old bathhouse, crossed a sealed cistern, and ended at a circle under the eastern court.

The royal archives.

The stolen records had not merely described ancient structures. They had been stored directly above one.

A customer entered before Elara could copy the final alignment.

The woman wore a travel-stained blue coat and carried a small astronomical clock with no maker's mark. Her hair was grey at the temples, her hands ink-stained.

"I was told this workshop repairs unusual mechanisms," she said.

Her father accepted the clock. "We repair honest ones too."

The woman's gaze settled on Elara's workbench.

The disk was covered by a cloth, but the silver insert remained beside it.

For one instant, the woman stopped breathing.

Then she smiled.

"That is fine workmanship."

"Scrap," Elara said.

"Of course."

She left the astronomical clock and paid in advance. Too much.

After she departed, Elara opened the case.

The clock contained no damage. It was running perfectly.

Inside the back plate, someone had engraved a line in an unfamiliar alphabet. Beneath it, in modern script, were three words:

ASH REMEMBERS SILVER.

Her father read over her shoulder.

"Do you know what it means?"

"No."

"Do you know who she was?"

"No."

"Good," he said. "For a moment I worried you had run out of questions."

Elara looked toward the street. The woman in blue had already disappeared.

The astronomical clock ticked steadily in her hands.

Then the stone disk beneath the cloth answered with a faint click.

The two mechanisms were keeping the same time.
$ep05$, 880),
        (6, $ep06$
Elara entered the undercity through a bathhouse drain while the capital slept.

The old bathhouse had been closed for twenty years after a section of floor collapsed into a forgotten cistern. Boards covered the main entrance. Ivy sealed the courtyard windows. The city had declared it unsafe, which usually meant no one important had found a profitable use for it.

Elara lowered herself through the broken floor with a coil of rope, the stone disk secured inside her coat.

The cistern below was dry. Mineral lines marked old water levels across the walls. At the eastern edge, a newer brick repair covered part of an older arch.

Newer meant only two hundred years old.

Elara removed three loose bricks and found a bronze plate behind them.

No keyhole.

No handle.

Just a shallow circle the size of the stone disk.

She placed it inside.

Nothing happened.

"Tell me your story," she whispered.

The disk sat slightly crooked. One edge had more wear than the other because the original mechanism had turned against pressure from below. Elara pushed the lower rim inward while rotating the silver spindle.

The wall moved.

Not opened - moved. A whole section of stone rolled sideways on hidden bearings with less sound than a cupboard door.

Cold air breathed from the passage beyond.

Elara lit a hooded lamp and entered.

The tunnel was not built like a sewer or crypt. Its walls curved without visible joints. Narrow silver lines ran through the dark stone, converging at intervals around empty recesses. Dust covered the floor except for one recent trail.

Someone had come this way before her.

Boot prints. Two people. One heavier, one with a slight drag in the left foot.

Elara followed until the passage divided.

The prints went right.

The map hidden in the disk pointed left.

She chose the map.

The tunnel descended into a chamber larger than the bathhouse above. Broken rings of stone surrounded a central column. Along the walls stood machines that resembled clocks only in the way a skeleton resembled a person: related in structure, stripped of everything familiar.

Elara approached the nearest.

Three silver arms hovered around a black sphere. One arm was bent. A later repair had fixed it in the wrong position, preventing the other two from completing their movement.

A mechanism carrying a mistake.

She removed the repair pin, straightened the arm, and released the spring.

The machine woke.

Silver light moved through the wall channels. One ring beneath her feet turned a fraction. The black sphere opened like an eye.

Elara saw the chamber from above.

She froze.

Her body remained beside the machine. She could feel the cold floor beneath her boots and the metal tool in her hand.

But she also saw herself as a small figure below.

The viewpoint drifted near the ceiling, silent and weightless. Every shadow sharpened. The lamp's flame seemed painfully bright. She heard the scratch of a beetle behind stone.

Then something moved in the right-hand passage.

Two figures carrying shuttered lanterns.

Elara blinked.

The impossible vision vanished.

She stood beside the machine again, heart hammering.

No time to understand.

She extinguished her lamp and climbed the central rings. The chamber remained visible in her mind as if moonlight filled it, although no light remained.

The two figures entered.

The woman in the blue coat came first. Behind her walked a broad man whose left boot dragged slightly.

"I told you the disk had returned to the workshop," the man said.

"And I told you the daughter would solve it before the father," the woman replied.

Elara held still above them.

The woman approached the awakened machine. "She has been here."

"Can it identify her?"

"Not this fragment."

"Then we take it."

They began removing the black sphere.

Elara shifted her weight. A grain of stone fell.

The man looked up.

Elara dropped.

She landed behind the woman, seized the sphere, and rolled beneath the silver arms before the man could catch her.

"Wait," the woman said. "We are not your enemy."

"That is what enemies say when they are losing."

The man blocked the mapped passage. Elara threw the black sphere toward him. He reached for it.

It opened midair.

A burst of silver light blinded him.

Elara ran through the other tunnel - the one marked by their footprints.

The route climbed sharply, ending at an iron hatch locked from above. Elara worked by touch. Six levers. Two false. One spring worn thin.

Behind her, the man's boots struck stone.

She lifted the correct levers, turned the cylinder, and opened the hatch into the cellar of a government records office.

Shelves crowded the room. Boxes of sealed documents filled every wall.

The royal archives.

Elara closed the hatch and reset the lock just as the man reached it from below.

A small brass label had been fixed to the nearest shelf.

FOUNDATION DISPUTES - EASTERN HOUSES.

She opened the first box.

Inside lay copies of land grants, court petitions, and a list of noble families claiming ownership of ground beneath the eastern district. Merchant Veyran's name appeared beside several payments.

The political conspiracy and the ancient machine occupied the same piece of earth.

Elara took one ledger and escaped through the office window before the night clerk returned.

At dawn, she reached the workshop.

Her father was already awake, lighting the front lamps.

He looked at the dust on her coat and the cut across her palm.

"Long walk?"

"Unexpected stairs."

He handed her a clean cloth without asking more.

Elara wrapped her hand and looked toward the astronomical clock left by the woman in blue.

Its silver pointer had moved.

It now indicated a symbol matching the machine beneath the city.

Elara remembered seeing herself from the ceiling. She remembered the silence, the sharp light, the sense of air beneath wings she did not possess.

For the first time in her life, a mechanism had told her a story she could not explain.
$ep06$, 996),
        (7, $ep07$
By the end of the week, everyone in the capital knew that the eastern noble houses were preparing for conflict.

No one agreed why.

At the market, one rumour accused House Ordan of forgery, another gave House Bellan river mercenaries, and a third blamed the king.

Elara trusted rumours only as evidence of what people wanted believed.

The ledger from the royal archives was more useful.

Veyran's payments connected lawyers, surveyors, and an unnamed collector who had bought stonework from the bathhouse, eastern court, and a shrine beyond the walls.

Someone was buying pieces of the ancient mechanism while encouraging noble houses to fight over the land above it.

Elara spent the morning repairing a clock in the home of Lady Ordan.

The sudden commission included an invitation no ordinary clockmaker would receive. Elara blamed Cedric.

She was wrong.

The grey-haired woman in blue waited in the music room.

Lady Ordan's servants had left them alone with a gilt mantel clock that needed nothing but dusting.

"You took the sphere," the woman said.

"You left it where anyone could."

"Almost no one could enter that chamber."

"Then you should meet more interesting people."

The woman smiled faintly. "My name is Serin."

"Is it?"

"It will serve."

Elara opened the clock case and removed the pendulum. "What do you want?"

"To know what the machine showed you."

"Poor workmanship."

Serin's expression remained calm, but her fingers tightened around one glove.

So the machine had been expected to do more than glow.

Elara continued, "You placed the astronomical clock in our workshop because it could find the disk."

"Not find. Answer."

"And the message?"

"A test."

"Of what?"

"Whether you would ask the right question."

Elara set the pendulum on the table. "You people do enjoy wasting time."

"We preserve what the kingdoms destroyed."

"By stealing records and burning warehouses?"

"We did not start the fire."

That sounded true, which made it more dangerous.

Footsteps approached outside the music room.

Serin moved toward a side door. "The conflict is meant to force the crown to open the eastern foundations. When the houses destroy one another's claims, someone else will own what lies beneath."

"Who?"

Serin looked toward the hall. "The person Veyran feared enough to keep copies."

She vanished through the side door as Cedric entered.

He wore court clothes and looked uncomfortable in them.

"Your clock is repaired," Elara said.

"It is not my clock."

"No wonder it resists."

Cedric closed the door. "Lady Ordan believes House Bellan stole the royal archive chest."

"They did not."

"I know."

"Progress."

He placed a folded paper beside the clock. "The seal used on the carriage belonged to a clerk in the eastern survey office. He disappeared yesterday."

Elara opened the paper. It listed emergency petitions from both houses. Each requested royal permission to excavate beneath the eastern court to prove an older boundary.

Different arguments. Identical phrasing.

"Someone wrote both petitions," she said.

Cedric nodded. "And arranged for each house to discover the other's."

Elara showed him three names from the payment ledger, keeping Serin's identity to herself.

"They connect to Veyran," Cedric said.

"They connect to the land beneath the court."

He studied her face. "You have been below it."

"Have I?"

"There is dust in your hair that does not occur above ground, and the cut on your hand came from old stone, not glass."

"People are not clocks."

"No. But they also leave marks."

Elara closed the mantel clock. He was improving far too quickly.

A servant knocked and announced that Lady Ordan's council had begun.

Cedric offered his arm.

Elara stared at it.

"We need to hear what they say," he said. "You cannot enter as a thief."

"I entered as a clockmaker."

"And clockmakers are not invited to private war councils."

"An error in etiquette."

She took his arm.

The council met in a gallery overlooking the eastern district. Lady Ordan accused House Bellan, and her lawyers presented the green-ribbon map.

Elara felt Cedric go still.

The map showed tunnels beneath the court. One line had been added in newer ink, directing excavation toward the ancient chamber.

A lawyer tapped the mark. "This passage proves our ancestral boundary."

It proved nothing. The line crossed original stone without accounting for level or structure. It was drawn by someone who understood maps but not mechanisms.

Elara leaned toward Cedric.

"The line is false."

"Can you prove it?"

"The ink is twenty years old. The mistake is two thousand."

Lady Ordan announced that workers would break ground at sunrise under armed protection.

Across the gallery, a servant dropped a tray.

Not clumsy. Deliberate.

While everyone looked, the lawyer folded the map and handed it to a messenger near the rear door.

Elara released Cedric's arm.

"I thought the chase was over," he murmured.

"This is not a chase."

She crossed behind the councillors, slipped through the rear door, and followed the messenger down the servants' stairs.

He moved quickly toward the stable yard.

Elara reached the outer passage first and locked the gate.

The messenger turned, drew a knife, and smiled without surprise.

"You are the fox."

"Disappointing, isn't it?"

He lunged.

Elara caught his wrist with the pendulum rod she had kept from the clock, twisted, and sent the knife across the stones. The messenger struck her shoulder and ran for the wall.

Cedric entered the yard from the opposite side.

The man stopped between them.

Elara and Cedric moved without speaking, blocking wall and gate. The messenger chose the stable.

A horse kicked him into a water trough.

Cedric pulled him out.

Inside the messenger's coat they found a second petition, this one instructing House Bellan to begin its own excavation at sunrise.

Two armed groups. One site. One carefully arranged collision.

Elara looked toward the eastern court.

Beneath it, the awakened machine waited.

Above it, nobles prepared to spill blood over a false line.

The mechanism was no longer alone.

The city itself had begun to speak.
$ep07$, 999),
        (8, $ep08$
The abandoned shrine stood beyond the northern wall where the road climbed into dry hills.

Elara left before sunrise with the green-ribbon map, Serin's astronomical clock, and enough food for one day. She told her father she was delivering a repaired instrument to a country estate.

He looked at the rope beneath her coat.

"Large instrument?"

"Awkward stairs."

"Of course."

He handed her an apple and said nothing more.

The shrine appeared near midday, half buried beneath windblown soil. Modern pilgrims had built a small stone altar against one wall, but the original structure was older than the capital. Its entrance faced neither the road nor the rising sun. It faced the city.

Elara found fresh horse tracks beside the ruin.

Serin had arrived first.

Inside, the air smelled of dust and cold iron. The walls were covered with symbols scholars had copied in books, usually beneath captions such as HOUSE CORVUS or TEMPLE OF THE SKY.

Elara saw mechanisms.

Lines curved around pivot points. Repeated marks indicated movement. Small changes in depth showed which parts were meant to slide across one another. The carvings were not heraldry. They were instructions.

At the centre of the inner wall appeared the interlocking arcs.

Beneath them, five angular characters formed a word.

VAELOR.

A scholar's plaque translated it as THE WINGED HOUSE.

Elara ran her fingers over the letters.

The plaque was wrong.

She could not read the Old Tongue, but the characters repeated inside the movement diagrams, always beside points where one system shifted into another state. Not a family. Not a house.

A function.

A change.

She touched the final character.

The world opened.

Sunlight vanished. Night flooded the shrine, sharp and silver. Elara heard wind moving across feathers. She saw the ruin from the broken roof, then from the hillside, then from high above the road.

A hawk circled below her.

No - not below.

She was above it.

The city lay on the horizon, every tower distinct. Something inside her body remembered how to tilt against the air.

Then the shrine returned.

Elara collapsed against the wall.

The astronomical clock had fallen from her hand. Its pointer spun wildly before stopping on VAELOR.

"That was stronger than the chamber."

Serin stood in the doorway.

Elara rose too quickly and nearly fell again. "You have a habit of arriving after the useful part."

"I was outside."

"Watching?"

"Waiting."

"For what?"

"For the Legacy to answer."

Elara drew a lock pick like a knife. "Explain."

Serin did not move. "The names survived. The meanings did not. Vaelor, Ferren, Caeryn. Modern scholars called them houses because they found the symbols beside human remains and assumed bloodline, rank, inheritance."

"And you do not?"

"We assume less."

"That is not an answer."

"No." Serin looked at the wall. "It may be a state of perception. A method of transformation. A role within a machine larger than this shrine. We know only that some people once carried the Legacies within themselves."

Elara's hand tightened around the pick.

"You think I carry one."

"The disk answered your workshop. The chamber woke for you."

"I repaired it."

"Yes. That matters."

Serin stepped closer to the diagram. "Others have stood before these mechanisms with the right ancestry, if ancestry is even the right word. Nothing happened. Others understood pieces of the machines but received no answer. You may be the first in generations to possess both."

Elara hated how neatly that sounded. Neat stories were often traps.

"Did you steal Veyran's letter?"

"We recovered one part before the collector could."

"You burned the warehouse."

"No."

"You followed me underground."

"Yes."

"Your man tried to take the sphere."

"He believed you would damage it."

Elara laughed once. "He knows nothing about me."

"Neither do I."

That honesty was more useful than reassurance.

Hooves sounded outside.

Serin's face changed.

"Not mine."

Men entered the outer chamber wearing the colours of the eastern survey office. Their leader carried a short crossbow.

"The collector wants the clock," he said. "And the girl."

Serin drew a narrow blade.

Elara looked at the wall.

The VAELOR diagram formed three linked channels. One line ran toward a cracked stone near the ceiling. Another descended beneath the floor. The third ended behind the altar.

A mechanism telling a story.

She pressed the cracked stone.

Nothing.

Wrong sequence.

The survey men advanced.

Elara closed her eyes and remembered the movement shown in the carving: rise, turn, release.

She pressed the floor mark first, rotated the altar's metal rim, then struck the cracked stone.

The shrine moved.

A section of roof collapsed between them, filling the chamber with dust. Elara pulled Serin through the opening behind the altar as crossbow bolts struck stone.

They emerged onto the hillside through a narrow ventilation shaft.

Serin coughed. "You knew that passage existed?"

"The wall did."

They ran downhill while the survey men searched the ruin.

At the road, Serin stopped.

"The collector will excavate beneath the eastern court tomorrow," she said. "The noble conflict is only cover. Once the foundations are open, he will remove the central mechanism."

"Who is he?"

Serin looked toward the capital.

"Master Halvek. Keeper of Royal Works."

The official responsible for repairing roads, walls, archives, and public buildings. A man with legal access to every foundation in the city.

Elara understood the scale at once.

Halvek did not need to break into ancient places.

The city paid him to open them.

Serin held out her hand for the astronomical clock.

Elara kept it.

"Trust remains difficult for you," Serin said.

"People are not clocks."

"No."

"They lie more."

Elara started toward the city.

Behind her, the shrine settled with a low grinding sound. For one moment she felt the wind again, high and cold, and knew exactly where every man inside the ruin stood.

She did not look back.

The Old Tongue had given her no answers.

It had given her a name for the question inside her.
$ep08$, 993),
        (9, $ep09$
Elara invited Cedric to the workshop after midnight.

He arrived through the front door.

She opened it before he knocked.

"You were followed," she said.

"I was careful."

"That is not the same as being successful."

Cedric glanced down the street. "Where?"

"The man pretending to sleep beneath the cooper's awning. He has changed boots since yesterday, but not his limp."

Cedric stepped inside. "Serin's man?"

"Halvek's."

Her father slept upstairs. The workshop lamps were turned low, leaving rows of clock faces in shadow. Elara had cleared the central bench and arranged the evidence across it: the copied ledger, the half map, the astronomical clock, drawings of the undercity mechanism, and a rubbing of VAELOR from the shrine.

Cedric placed a sealed court file beside them.

"Master Halvek requested emergency authority to stabilise the eastern foundations," he said. "The order allows him to remove any object considered a structural danger."

"Convenient."

"He also advised both houses that the other intended to seize the site."

Elara opened the file. The order carried the royal works seal. Authentic.

The supporting survey was not.

"The measurements repeat," she said.

Cedric leaned over the page.

"Here. The depth beneath the eastern court is copied from the old bathhouse collapse. Halvek reused the figures because he has not reached the central chamber yet."

"Can we prove that before sunrise?"

"Yes."

Cedric waited.

Elara smiled. "You dislike that answer."

"I dislike answers that arrive without methods."

"You are becoming demanding."

She placed the stone disk's silver insert over the survey map. Its three notches aligned with three marked foundations: the bathhouse, the shrine, and the eastern court.

The mechanisms were connected.

The green-ribbon document had been a route map. The blue-waxed letter likely identified who could authorise excavation. The black-cord cylinder carried the physical key.

Three pieces, each useless alone.

Cedric unfolded a small page from the court file.

"Veyran's original statement."

The merchant had written it before withdrawing his complaint. One line had been heavily crossed out.

Elara held it above a lamp. Scratched ink changed the paper's thickness.

She read the hidden words through the back.

At first bell, place the silver within the ash. The eastern claim will fall.

Cedric frowned. "A signal?"

"A mechanism."

"Ash?"

Elara looked at the astronomical clock's engraved message.

ASH REMEMBERS SILVER.

Not poetry. Instruction.

"Halvek has the black cylinder," she said. "We have the silver insert. He needs both."

"Then why begin the excavation?"

"Because he thinks I will bring it."

Cedric looked toward the dark window.

The man beneath the cooper's awning was gone.

A soft click sounded at the rear door.

Elara extinguished the nearest lamp.

The lock began to turn from outside.

She listened.

Three pins lifted cleanly. The fourth scraped. Whoever held the pick was skilled but impatient.

Elara remembered herself at ten, opening the workshop door again and again after closing time. Her father had found the mark beside the keyway the next morning.

"Use less tension," he had said.

Now she placed one finger against the inner cylinder and added pressure.

The pick outside snapped.

A curse followed.

The front window shattered.

Cedric pulled Elara behind the bench as a bolt struck the wall. Two men entered from the street. The rear door burst inward under a shoulder.

Halvek's limping agent came through first.

"Take the insert," he ordered.

Cedric drew his sword.

Elara did not have one. She had the workshop.

She kicked the release beneath the repair rack. A dozen suspended clock weights dropped at once, smashing lamps and scattering the attackers. Darkness filled the room.

Elara knew every bench by distance and every hanging chain by sound.

She moved between them.

One attacker struck where she had been. Elara looped a winding cord around his wrist and pulled him into a cabinet. Cedric met the second near the window. Steel rang once, twice, then stopped.

The limping man reached the central bench.

His hand closed around the silver insert.

Elara heard the tiny scrape.

In the darkness, another sense opened.

She smelled wet leather, lamp oil, iron, fear. She heard blood moving beneath skin. The man's position became as clear as a mark on a map.

Not sight.

Something lower, closer to the ground.

Wolf.

The word arrived without explanation.

Elara crossed the room and caught his arm before he knew she had moved.

He twisted free and ran through the rear door with the insert.

Cedric followed.

Elara stopped beside the bench.

The silver insert still lay beneath her hand.

The thief had taken a copy she had cut from tin.

Cedric returned moments later, breathing hard.

"He escaped."

"Good."

"You gave him the key?"

"I gave him a story he wanted to believe."

She held up the true insert.

Cedric stared, then laughed despite himself.

Upstairs, a floorboard creaked.

Her father stood at the stair landing in his nightshirt, holding a heavy clock hammer.

He surveyed the broken window, unconscious attacker, and sword in Cedric's hand.

"Long walk?" he asked Elara.

"Unexpected guests."

Her father looked at Cedric. "And you are?"

"Cedric."

"The noble."

Cedric appeared unsure how to answer.

Her father pointed the hammer toward a broom. "If you are staying, make yourself useful."

While Cedric swept glass, Elara studied the false key's route in her mind. Halvek would carry it to the eastern court believing the final piece had arrived.

At first bell, he would begin.

And for once, Elara intended to let the thief reach the lock before she did.
$ep09$, 917),
        (10, $ep10$
The first bell rang over the eastern court as two noble houses faced one another across an open trench.

Ordan guards stood north, Bellan guards south. Between them, Halvek's workers had exposed a wall of ancient black stone.

Halvek held a royal order above the crowd.

"By authority of the crown, this site is under the protection of Royal Works."

Both houses shouted that the ground belonged to them.

Exactly as he intended.

Elara watched from the clock tower. Cedric waited below with the forged survey.

Halvek's limping agent entered the trench with the false silver insert.

Good.

Elara descended through the tower shaft and entered the excavation by an old drain. Workers had uncovered a circular doorway marked with the interlocking arcs.

The black-cord cylinder was already fixed into its centre.

The false insert lay beside it.

Halvek knelt before the mechanism.

Elara saw him clearly: an older man with a builder's hands and dust beneath his nails. He looked like a craftsman, not a collector.

That made sense.

He had read enough of the city's hidden story to want ownership of the ending.

"The key is wrong," his agent said.

Halvek examined the tin copy. "She expected you."

"She could still be above."

"She is below," Halvek said.

Elara stepped from the passage.

"Better."

The agent reached for his knife.

Halvek lifted one hand. "You opened the bathhouse chamber."

"I repaired it."

"You awakened Vaelor."

"I woke a machine."

His eyes brightened. "You still think there is a difference."

Above them, the argument in the court grew louder.

Halvek gestured toward the ancient door. "The kingdoms built their laws on ruins they cannot understand. Noble families claim ownership because dead clerks copied dead boundaries. Scholars invent names and call ignorance tradition. I found the mechanisms. I preserved them."

"You burned a warehouse."

"A necessary distraction."

"You arranged a war."

"A temporary pressure."

"Mechanisms are less forgiving than people," Elara said. "People occasionally choose not to crush you."

Halvek smiled. "Give me the silver."

Cedric's voice sounded from the trench entrance. "Master Halvek, you are under arrest for falsifying a royal survey."

Halvek's agent drew his knife.

The court erupted as Cedric's officers moved against Halvek's workers.

Halvek drove the black cylinder deeper into the doorway.

The mechanism began to turn.

The false insert had not opened it, but the pressure released something beneath the floor. Cracks spread through the trench walls. Stone groaned overhead.

"Stop it," Cedric said.

Halvek backed away. "It has begun."

Elara knelt beside the door.

The cylinder forced the spindle to rotate while one ring remained fixed. Halvek had mistaken access for understanding.

Elara removed the true silver insert from her sleeve.

Cedric saw it. "You brought it."

"He would have opened the wall with or without me. This lets me decide how."

She fitted the insert into the wing-shaped slot.

Nothing happened.

The trench shook again.

Elara closed her eyes.

Every mechanism tells you a story.

The black cylinder was not a key. It was a weight. The silver was not a key either. It was a regulator. Ash and silver: pressure and balance. Destruction remembered by precision.

She turned the silver against the black.

The rings aligned.

"Now," she whispered. "Tell me."

The doorway opened inward.

Ancient braces unfolded beneath the court and caught the failing stone. Elara's correction stabilised the square.

Cedric looked upward. "The houses will see that the foundation does not follow either claim."

The opening exposed noble boundary stones inserted centuries after the ancient wall, visible to every surveyor.

The political argument ended not with agreement, but with the destruction of both stories.

Halvek stared into the doorway.

"You do not know what is inside."

"No," Elara said. "That is the interesting part."

He lunged for the opening.

Cedric caught him.

The limping agent moved toward Elara, but Serin appeared from the side passage and placed a blade beneath his chin.

"You are late," Elara said.

"I was bringing witnesses."

Serin brought scholars, a royal surveyor, Lady Ordan, and Lord Bellan.

Both nobles saw the altered boundary stones.

Neither looked pleased.

That, Elara thought, was the beginning of truth.

Halvek was taken above in chains while the scholars began arguing over ownership.

Elara ignored them and entered.

Cedric followed.

The chamber beyond was circular and untouched by dust. Silver lines spread across the floor like moonlight trapped in stone. At the centre stood a tall mechanism of black rings surrounding an empty space.

No treasure.

No weapon.

Another door.

Its surface carried the word VAELOR.

Elara approached.

The silver lines brightened beneath her feet.

"Are you doing that?" Cedric asked.

"No."

For once, she was certain.

The chamber vanished.

Wind rushed around her. She saw the capital from high above: roofs, towers, river, roads, every hidden route laid open. She felt wings extend from shoulders that no longer seemed shaped like shoulders.

Below, far below, Cedric stood beside her human body.

"Elara?"

She tried to answer.

A sound left her - not a word, but the low call of an owl.

The vision folded inward.

Elara returned to the chamber on one knee, Cedric's hand gripping her arm. A single pale feather drifted between them and settled on the silver floor.

Neither spoke.

Elara picked it up.

It was real.

Behind the black rings, the second door began to open.

Darkness waited beyond it, deep and cold and full of mechanisms no modern hand had touched.

Cedric looked at the feather. "Do you know what just happened?"

"No."

"Are you frightened?"

Elara considered the question.

The honest answer surprised her.

"A little."

Then the darkness beyond the door clicked.

One patient sound.

A beginning.

Elara rose, feather in one hand and a lock pick in the other.

Her father's voice lived quietly in her memory.

Do not force it. Listen first.

She smiled at the unknown.

"Tell me your story."
$ep10$, 981)
)
UPDATE public.episodes AS e
SET
    script_text = episode_scripts.script_text,
    word_count = episode_scripts.word_count,
    updated_at = now()
FROM public.stories AS s,
     episode_scripts
WHERE s.id = e.story_id
  AND s.slug = 'ash-and-silver'
  AND e.season_number = 1
  AND e.episode_number = episode_scripts.episode_number;

COMMIT;

-- Verification
SELECT
    e.season_number,
    e.episode_number,
    e.title,
    e.word_count,
    LENGTH(e.script_text) AS character_count,
    e.episode_status,
    e.audio_url
FROM public.episodes AS e
INNER JOIN public.stories AS s
    ON s.id = e.story_id
WHERE s.slug = 'ash-and-silver'
  AND e.season_number = 1
ORDER BY e.episode_number;
