pl_control/var
	PLASMA_DMG = 3

	CLOTH_CONTAMINATION = 0 //If this is on, plasma does damage by getting into cloth.

	PLASMAGUARD_ONLY = 0 //If this is on, only biosuits and spacesuits protect against contamination and ill effects.

	GENETIC_CORRUPTION = 0 //Chance of genetic corruption as well as toxic damage, X in 10,000.

	SKIN_BURNS = 1       //Plasma has an effect similar to mustard gas on the un-suited.

	EYE_BURNS = 1 //Plasma burns the eyes of anyone not wearing eye protection.

	CONTAMINATION_LOSS = 0.01

	PLASMA_HALLUCINATION = 0

	N2O_HALLUCINATION = 1


obj/var/contaminated = 0

obj/item/proc
	can_contaminate()
		//Clothing and backpacks can be contaminated.
		if(flags & PLASMAGUARD) return 0
		if(flags & SUITSPACE) return 0
		else if(istype(src,/obj/item/clothing)) return 1
		else if(istype(src,/obj/item/weapon/storage/backpack)) return 1

	contaminate()
		//Do a contamination overlay? Temporary measure to keep contamination less deadly than it was.
		if(!contaminated)
			contaminated = 1
			overlays += 'icons/effects/contamination.dmi'

	decontaminate()
		contaminated = 0
		overlays -= 'icons/effects/contamination.dmi'

/mob/proc/contaminate()

/mob/living/carbon/human/contaminate()
	//See if anything can be contaminated.

	if(!pl_suit_protected())
		suit_contamination()

	if(!pl_head_protected())
		if(prob(1)) suit_contamination() //Plasma can sometimes get through such an open suit.

	if(istype(back,/obj/item/weapon/storage/backpack))
		back.contaminate()

/mob/proc/pl_effects()

/mob/living/carbon/human/pl_effects()
	//Handles all the bad things plasma can do.

	//Contamination
	if(vsc.plc.CLOTH_CONTAMINATION) contaminate()

	//Anything else requires them to not be dead.
	if(stat >= 2)
		return

	//Burn skin if exposed.
	if(vsc.plc.SKIN_BURNS)
		if(!pl_head_protected() || !pl_suit_protected())
			burn_skin(0.75)
			if(prob(20)) src << "\red Your skin burns!"
			updatehealth()

	//Burn eyes if exposed.
	if(vsc.plc.EYE_BURNS)
		if(!head)
			if(!wear_mask)
				burn_eyes()
			else
				if(!(wear_mask.flags & MASKCOVERSEYES))
					burn_eyes()
		else
			if(!(head.flags & HEADCOVERSEYES))
				if(!wear_mask)
					burn_eyes()
				else
					if(!(wear_mask.flags & MASKCOVERSEYES))
						burn_eyes()

	//Genetic Corruption
	if(vsc.plc.GENETIC_CORRUPTION)
		if(rand(1,10000) < vsc.plc.GENETIC_CORRUPTION)
			randmutb(src)
			src << "\red High levels of toxins cause you to spontaneously mutate."
			domutcheck(src,null)

/mob/living/carbon/human/proc/burn_eyes()
	//The proc that handles eye burning.
	if(prob(20)) src << "\red Your eyes burn!"
	eye_stat += 2.5
	eye_blurry = min(eye_blurry+1.5,50)
	if (prob(max(0,eye_stat - 20) + 1) &&!eye_blind)
		src << "\red You are blinded!"
		eye_blind += 20
		eye_stat = 0

/mob/living/carbon/human/proc/pl_head_protected()
	//Checks if the head is adequately sealed.
	if(head)
		if(vsc.plc.PLASMAGUARD_ONLY)
			if(head.flags & PLASMAGUARD || head.flags & HEADSPACE) return 1
		else
			if(head.flags & HEADCOVERSEYES) return 1
	return 0

/mob/living/carbon/human/proc/pl_suit_protected()
	//Checks if the suit is adequately sealed.
	if(wear_suit)
		if(vsc.plc.PLASMAGUARD_ONLY)
			if(wear_suit.flags & PLASMAGUARD || wear_suit.flags & SUITSPACE) return 1
		else
			if(wear_suit.flags_inv & HIDEJUMPSUIT) return 1
	return 0

/mob/living/carbon/human/proc/suit_contamination()
	//Runs over the things that can be contaminated and does so.
	if(w_uniform) w_uniform.contaminate()
	if(shoes) shoes.contaminate()
	if(gloves) gloves.contaminate()


turf/Entered(obj/item/I)
	. = ..()
	//Items that are in plasma, but not on a mob, can still be contaminated.
	if(istype(I) && vsc.plc.CLOTH_CONTAMINATION)
		var/datum/gas_mixture/env = return_air(1)
		if(env.toxins > MOLES_PLASMA_VISIBLE + 1)
			if(I.can_contaminate())
				I.contaminate()