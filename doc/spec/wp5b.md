# DHCF WP5b: Industry publication library - Implementation


This project is commissioned by the Digital health Commons Forum, a not-for-profit organisagtion based in Luxembourg and funded by the Luxembourg Ministry for the Economy.

## Work package parameters

- Start date: Immediately on assignment
- Deadline: 6 week from commencement
- Priority: High
- Budget (Time): 15 days
- Business justification: Create high value resource of industry papers to encourage visitors and to draw from to develop content. 
- Business measure/outcome: Library available and meets brief, code committed to public repo with OSS licence
- Decisions delegated: Research
- Situations that must be escalated: Any variance to functionality, budget or timetable
- Progress or completion reporting requirement: Installation instructions, technical summary of build, OpenChain audit
- Where to go for support and guidance: Stuart 

Assignment
: Paul W 10 days (80 hours)
Alex 5 days (40 hours)

## Brief

As defined in WP5a, build and deploy container based OSS library.

Based on DITO document library content initially, UI to add other content directly, or to batch process.

One component will involve feeding a few hundred DITO pdf and summaries, web pages, videos and docx academic or industry documents in to a local processor to create a graph, and index, extract keywords, references etc to feed in to a database. 

Performance isn't critical as the process is non-interactive, quality of output is the priority.


### Activities

- Create git repo under DHCF org (https://github.com/Digital-Health-Commons-Forum)
- Create deployable container with Compose file, to be operated at Cloudient
- Create app in Mojo or similar technology
- Develop in the open

### Characteristics

- Markdown connected to resources - can be attachments or URLs
    - Paul
    - Alex
- Index, searchable
    - Paul
    - Alex
- keyword extraction from source documents
    - Paul
- presented with basic DHCF theme according to style guide
    - Alex
- Content notification via RSS  / Atom / ActivityPub
    - Alex
- Update notification via email / ActivityPub
    -   
- Browse by topic / keywords grouped and tag cloud
    - Paul
    - Alex
- Comments & opinions, human summaries
    - Alex
- Enables writing new content (Jaana) based on a group of articles, publish grouping article
    - Paul
    - Alex
- Easy URI permalink references for external micro blogs across channels
    - Paul
    - Alex
- Easy add new resources
    - Alex
- OAuth
    - Paul
    - Alex


### Paul Timesheet
* 18/11/2024 - 3 Hours (3h)
    * 0.5 Hours - Github base creation and license enaction
    * 2 Hours - Planning development and dockerization with optimization of decided bases
        * We are using SQLite instead of PostGreSQL due to most information being stored in minio
    * 0.5 - Meetings, Chat, Planning other
* 23/11/2024 - 6 hours (9h)
    * Initial coding session, carton installation
* 1/12/2024 - 1 hours (10h)
    * Meeting with Alex / Planning
    * Carton implementation
    * Docker lib install/testing
* 2/12/2024 - 1.5 hours (11.5h)
    * Schema development
    * General development
* 3/11/2024 - 10.5 hours (22h) %i
    * main.pl development, Dockerfiles
    * Debugging dzil->carton->docker pipeline
    * Installing and configuring S3 module
    * Configuring required modules
* 4/12/2024 - 2 hours (24h)
    * Extended API connectivity
* 4/12/2024 - 1.15 hours (25.25h)
    * Discussion with Alex over api outputs and design
* 4/12/2024 - 2 hours (27h)
    * Start of implementation of api changes discussed with Alex
- incoiced to
* 7/01/2025 - 3 hours (30h)
    * Beginning of implementing full Minio capability
        * Auto bucket creation (init)
        * Attempting to implement in perl (failed)
* 8/01/2025 - 2 hours (32h)
    * Rewriting mini worker in python due to lack of correct support in perl
* 9/01/2025 - 2 hours (34h)
    * Connected mini worker to main core, started work on init-worker to deal with minio issues
* 10/01/2025 - 1 hour (35h)
    * Alpha init process created, needs bug resolution on restart



## Alex Timesheet
* 3/12/2024 - 1 Hour
    * Configure code folder for git and do initial commit as well as restructure to fit git repo better 
* 4/12/2024 - 1.15 hours
    * Build out initial index page
* 4/12/2024 - 1.30 hours
    * Discussion with Paul over api outputs and design
* 5/12/2024 - 1 hour
    * Finish initial index page allowing users to view document list with client side filter (this will move to api filter later)
* 5/12/2024 - 1.5 hours
    * Build initial document view
* 6/12/2024 - .5 hours
    * Start building basic login screen
* 6/12/2024 - 1 hour
    * Catch up and get each side of the stack joined up so we can both run it in docker
* 17/12/2024 - 45 mins
    * Meeting With David, Stuart and Paul to update on progress