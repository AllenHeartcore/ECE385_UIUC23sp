# Writing A TrapoScript

## **Terminology**

- *Phrase*: a continuous sequence of *beats* that form a "sentence" in music
- *Beat*: a basic unit in music that contains exactly one stress; the "B" in "BPM" 
- *Tick*: the points on which *keys* are **normally** placed within a *beat*
- *Key*: a single note that must be struck at the right time on the keyboard
- *Marker*: a special character that is not a note but marks special formats in a *phrase*

In short, a *phrase* = multiple *beats*, a *beat* = multiple *ticks*, and *keys* **usually** fall on *ticks*. <br> A *phrase* string consists of *keys* and *markers*. 

## **The Header**

A valid TrapoScript header, on a separate first line, has the following format: 

    TrapoScript <BPM> <BPP> <TPB> <BOfst>

- BeatsPerMinute (`BPM`): can be integer or float
- BeatsPerPhrase (`BPP`): must be integer; **must be power of two**
- TicksPerBeat (`TPB`): must be integer
- BeatOffset (`BOfst`): can be integer or float
  - This is the time duration (in *beats*) before the first *beat* appears

All four numbers should be **positive**. 

## **The Body**

The body of a TrapoScript contains several *phrase* strings of the **same number of *keys***, each on a line. 

In a *phrase* string, each character can either be a *key* -- that is, one of
```
b c d e f g h i j k l m n o p r s t u
v w x y 2 3 4 5 6 7 8 9 0 , . ; - = [
```
-- or a *marker*. Valid *markers* include:

- <code>\`</code>: an "empty key" that lasts for a *tick*
- `()`: this marks a Multikey Section in which multiple *keys* appear on the same *tick*
- `{|}`: this marks a Multihand Section in which each hand plays a *subsection*
  - Format: `{Subsection 1|Subsection 2|...|Subsection N}`
  - *Subsections* interleave in time and must have the **same number of *keys***
- `<>`: this marks an Accelerated Section in which *keys* may appear between *ticks*
  - Each pair of `<` and `>` accelerates the speed by a factor of 2
  - Example: <code><\`\`></code>, <code><<\`\`\`\`>></code>, and <code><\`<\`\`>></code> all last for 1 *tick*

You can nest and combine *markers* in (some) various ways (but not others):

| Situation | Valid? | Example |
| - | - | - |
| Nested Multikey | **No** | `(tu(dgjl))` |
| Nested Multihand | **No** | `{bn\|{rf\|ko}}` |
| Nested Acceleration | Yes | `<<5tgb6yhn>>` |
| Multikey inside Multihand | Yes | `{(vbn)y\|o(m,.)}` |
| Multikey inside Acceleration | Yes | `<(tb)(yn)(um)(i,)>` |
| Multihand inside Multikey | **No** | `(yu{fg\|kl})` |
| Multihand inside Acceleration | Yes | `<5656{cxcx\|nmnm}>` |
| Acceleration inside Multikey | **No** | `(ko<,lp->)` |
| Acceleration inside Multihand | Yes | `{<4rfv>\|<nji9>}` |
| Empty key inside Multikey | **No** | <code>(fh\`k)</code> |
| Empty key inside Multihand | Yes | <code>{ee\`e\|o\`o\`}</code> |
| Empty key inside Acceleration | Yes | <code><cv\`bn\`m,></code> |

## **Putting It Together**

Here is a practical example of TrapoScript: 
```
TrapoScript 240 8 2 0.6
{c``c3``c`c`c3`c`|n<m,>nm(90)m,(io)n(io)m,(90)`m`}
```
This (single) *phrase* will translate to:
```
  BEAT    |1  |2  |3  |4  |5  |6  |7  |8  |
  TICK    | | | | | | | | | | | | | | | | |

 HAND 1   c     c 3     c   c   c 3     c
----------
 HAND 2           9     i   i     9
          n m,n m 0 m , o n o m , 0   m
```
in which
- each vertical line represents a *tick*
- each *phrase* has 8 *beats* and `BPP * TPB` = 16 *ticks*
- the first `|` starts at `60 / BPM * BOfst` = 0.15 s
- and each `| |` represents `60 / BPM / TPB` = 0.125 s

## **Misc. Specifications**

- Use Linefeed (`\n`) instead of Carriage Return (`\r`)
- There should be **no** empty line in a TrapoScript, except that……
- There should be **at least one** final newline
- There should be **no** whitespace (except for those between the numbers in the header)
- Max song length: **2:11.071** (or 131,072 ms)
- Max number of *keys* in the whole TrapoScript: 65,535
- Max number of *keys* and *markers* per phrase: 1,024
- There are only "touches" -- no "holds" or "flicks" -- in TrapoTempo
  - This doesn't mean the game is simple. You've got 42 keys! 
- In the TrapoChart, time is recorded in "units" of 2 ms
  - So each second is 500 units. This limits judgement accuracy. 
