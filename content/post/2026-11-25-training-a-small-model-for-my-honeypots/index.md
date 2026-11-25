---
title: "Training a small model for my honeypots"
date: 2026-11-25T16:00:00-05:00
categories: [machine-learning]
description: "What the SSH and database sessions on threat.gg tell me about scanners, and what happened when I trained a small model to keep those conversations going."
draft: true
---

I build threat.gg, a network of honeypots you can run on your own servers. An SSH sensor lets a visitor log in to a decoy shell and records what they type. If all I kept were the source IP, the username and the guessed password, I'd miss my favorite part of the summer's traffic. A surprising number of those visitors wanted to know what graphics card the machine had.

Over two months the sensors recorded 54,613 GPU checks across 24,038 SSH sessions. I could open a session and see a client ask about the kernel and CPU, then look for a graphics device. The SSH client banner gave me another way to group those visits when the source address changed. I could tell someone was inventorying GPUs. From those commands alone I'd have a hard time saying whether they wanted a miner or a box to run inference on. [The summer SSH campaign report](https://threat.gg/blog/ssh-threat-actors-may-july-2026) has the breakdown.

## What I get out of answering

Those summer sessions predate the small model. The reason to build one was sitting in the command archive. By October it held nearly 40,000 distinct SSH command patterns. A few lines of Go will give me a good answer to `nproc`, but someone has to write and maintain each of those canned answers. I wanted the common commands to keep using those cheap, predictable answers and a small model to handle the rest. It had to remember which machine it was pretending to be. It also had to be fast enough to answer a database client that gives its first query half a second.

When I open a recorded shell session, I can see what the visitor typed, the working directory, our reply and its exit code. SQL has its own version of this. In one two-hour production check I could match all 10,918 PostgreSQL generation records back to stored queries. That lets me read a query alongside the result our service generated for it. The record also points back to the earlier turns and the machine profile used for the answer. If the decoy claims it has an NVIDIA card, that's a detail about *my decoy*. What I learned about the visitor is that they asked about the card. Their next command is a separate observation.

![How a threat.gg session joins visitor input and decoy reply history, with a separate link from an observed download command to a captured file.](session-evidence.png)

I had a hunch about the GPU scans. Were bots leaving because they didn't like the hardware we showed them? In an October comparison, 623 sessions went on to issue a download command and about 48,700 stopped. Both groups got much the same mix of answers to the CPU-count and graphics-device checks. I couldn't credit a particular reply for getting us to the download.

When we *do* capture a file, its SHA-256 lets me find other commands that delivered the same bytes under different names. One backfill of the older SSH data connected over 120,000 command-to-file links to just 2,201 distinct samples. That lets me start from a file and work backwards to the sessions where it turned up.

## Why train a model this small?

I wanted one model I could host myself for SSH, Telnet, PostgreSQL and SQL Server. Sending a shell command and its recent history to a hosted model adds a round trip and means handing that provider the transcript. The first-query SQL timeout is especially unforgiving. Our larger model needs a budget of at least 1.5 seconds before the service will even try it.

I let Codex work on the training for most of a month. By my count I'd spent over $200 on Runpod, and when I wanted my 4080 back to play games, I still deployed the sixth revision, r6. The newer one, r11, had spent a lot more time on rented GPUs. I couldn't show that it gave better answers.

I started with SSH and used replies from a larger model as training examples for a smaller one. That's most of what I mean by *distillation* here. The first run used 17,849 examples and took about an hour to train on an H100. I used LoRA, which let me train a small set of extra weights and merge them into the model afterward. I also had to check what I was teaching it. The larger model sometimes contradicted the machine's own specs or reported an impossible uptime.

Early on I tried three small models on the cleaned-up SSH data. Qwen3-0.6B won that comparison, and its quantized model file came in at about 391 MB. I could run that on hardware I already had.

Some of the most productive training runs were pretty boring. The model had trouble with the statements SQL Server clients send when they first connect, and with PostgreSQL queries that specify a row limit. I added examples of both. On the same checks, r6 answered 29 of 30 SQL Server openers correctly, up from 27. On the PostgreSQL limit cases it went from 27 of 32 to 31. Training took about 96 minutes on an L40S.

The PostgreSQL transcripts also gave me a bug report I never would have written myself. In roughly 15 hours after the r6 rollout, the validator rejected 205 PostgreSQL replies. Of those, 201 were answers to the same role-count query. Run early in a replayed session, the query got a single value. After a wider table result, the model sometimes put two values in a one-column row. The scanner had asked a perfectly ordinary counting question. It was our answer that was broken. Keeping the earlier result alongside the query gave me a way to reproduce it and a reason to put multi-turn SQL examples in the next training set.

I ran the r10 model through 100 test sessions and it passed 88. The older r9 weights paired with the r10 client passed 92. The client had learned how to recover complete rows from a partial SQL reply. That was a useful change to the Go code, but I still wanted a single model I could export, put on another box, and get the same answers from.

## What was actually in a training batch?

One r11 run stopped after 3,200 minibatches. The files on disk included plenty of long answers. When I counted the batches the trainer had actually read, it had gone through about 9% of the intended material and had barely seen the longest answers. Those were exactly the ones I wanted it to finish.

There was also an off-by-one error on the Mac training path. Training batches use padding so sequences of different lengths fit together. A mask tells the trainer which tokens count toward the loss. The checker I'd been looking at used unpadded examples. When I looked at an actual padded batch, the mask included one extra token on every row. Token zero decodes to an exclamation mark.

![Two loss masks over the same training row. Both score the answer, end-of-sequence token and newline. The original also scores the first padding token, which decodes to an exclamation mark.](loss-mask.png)

The test I like for this one is to change the contents of the padding and run the same batch twice. After fixing the end index, I got identical loss and gradients. I'd keep that test even if I threw the model away. It catches the extra token regardless of what the model eventually learns to print.

With the mask fixed, I ran the 0.6B model twice with different random seeds. Each run went through 34,626 minibatches, grouped into 199 weight updates. The exported models passed 94 and 95 of 100 sessions on the benchmark I was using then. Both fell short on SSH, and neither met the tighter limit on malformed replies. I kept both checkpoints.

## Was I being too picky?

I also tried a larger Qwen with 1.7 billion parameters. For one of those runs (Q44 in my notes), I could compare the starting checkpoint and the trained model session by session. A session is a whole conversation with the honeypot. One bad answer can spoil a run of otherwise sensible replies.

![Of 100 matched sessions, 75 passed both checkpoints and 20 failed both. Two went from fail to pass after training and three went from pass to fail.](matched-sessions.png)

The starting checkpoint passed 78. After training it passed 77. PostgreSQL accounted for 14 of the 23 failures. In a separate SQL check, the model got the column type right for a timestamp and put a value in the cell that our Go parser couldn't read. I changed just the timestamp text in copies of the saved replies. All eight parser rejections cleared. That's a tempting reason to rent another GPU and train on dates.

Before doing that I went back to the 100 sessions. Nine of the failures had *only* a reply-format flag. Even giving the model all nine for free gets it to 86, and the release target is 92. Another session had both a format error and wrong rows, so it would still fail. I put the GPU rental on hold.

## Getting my gaming PC back

I still needed somewhere to run r6. I got a US A4000 on Runpod for $0.174 an hour including disk, about $129 for a 31-day month at that rate. On the first burst test, with up to 12 requests in flight, the model answered only 8 of 36 ordinary requests before their three-second deadline.

The biggest improvement came from turning *off* llama.cpp's extra RAM prompt cache. I kept HTTPS connections pooled for both runs, kept the same weights and 12 slots, and changed the cache from 2 GiB to zero. That got 28 of 36 replies back in time. I also tried FP16 for the attention key/value cache. With that setup, one request at a time, 10 of 12 first SQL queries made their much shorter 500 ms deadline. Sending those queries in bursts still got me zero of 18.

I moved production over for a short trial on November 25. In the first five minutes or so the student answered 128 of 134 attempts, with a median of 614 ms for the replies it served. Most were SSH. There wasn't a single PostgreSQL reply in that sample, so I still want to see what happens during a busy stretch of database traffic.

Training is paused. The next thing I want to know is whether either of those old 199-update checkpoints beats r6 on sessions it hasn't seen. First I need to check which test examples or templates made it into their training data. If there's a clean comparison left, I already have the three model files I need to run it.
