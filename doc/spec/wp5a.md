# DHCF WP5a: Industry publication library - Analysis & design


This project is commissioned by the Digital health Commons Forum, a not-for-profit organisagtion based in Luxembourg and funded by the Luxembourg Ministry for the Economy.


## Work package parameters

- Start date: Immediately on assignment
- Deadline: 1 week from commencement
- Priority: High
- Budget (Time): 2 days
- Business justification: To establish available components before undertaking Phase 2
- Business measure/outcome: Reduced risk for phase 2 
- Decisions delegated: Research targets
- Situations that must be escalated: Any risk to timeline, budget or features
- Progress or completion reporting requirement: Summary on shared Codi document of findings
- Where to go for support and guidance: Stuart (Alex for hosting / auth)

Assignment
: Paul W 1.5 days
Alex 0.5 days


## Brief

Research is the first component in WP5 - to define and specify the technological approach to [WP5b](https://codimd.mackintosh.me/FnEwv6OiSV-JfrchNFNTCA#).

The library will initially be populated with the DITO background documents and human-created summaries ([available on this link until end Jan 2025](https://nextcloud.mackintosh.me/index.php/s/25J5z47K5jfA7pD)).

The delivered project will be a hyperlinked knowledge graph with web interface to browse and search.

Content may be the binary or link to the binary of the following types:

- PDF
- HTML
- Markdown
- docx
- odt
- jpg
- png
- video formats

Developer to decide if content should be in S3 bucket or similar rather than local file system.

Developer to decide if Small Language Model (SLM) is required, or if just parsing the source with Perl libraries.

It may be that there is an OSS SLM engine off the shelf, or Perl document processing libraries. 

Propose software licence
Document choices to conform with OpenChain

# Project Plan for WP5a: Industry Publication Library - Research (PGW Notes)

## Objective
The goal of WP5a is to establish a comprehensive technological approach for the creation of a hyperlinked knowledge graph with a web interface for browsing and searching a library of industry publications. This research will serve as the foundation for WP5b, which will focus on implementing the approach. The content will primarily consist of DITO background documents and human-created summaries.

## Technical Approach

### 1. Document Storage and Management
- All documents will be stored in a **MinIO** object storage system, ensuring scalability and high availability.
- A duplicate document tree will be created with metadata (e.g., Header, Title, Speaker, Subject) extracted from each document. This will help to categorize and describe the documents efficiently.
   
### 2. Web Server and Interface
- The final web server will be built using a mixture of **Mojo**, a Perl-based framework suitable for high-performance web applications as well as **Node** to allow easier api integration. This may be adjusted as development proceeds, based on emergent needs.
- The entire application stack will be containerized using **Docker** to ensure ease of deployment and scalability.
   
### 3. Database
- The primary database for storing metadata and processed content will be **SQLite**, ensuring robust data management and querying capabilities.

### 4. API Design
- The system will expose an **OpenAPI v2** interface for interactions between components (such as workers and the web interface).
- An **OpenAPI v2 schema** will be created to define the structure of the API and facilitate integration with the components.
   
### 5. Content Processing Pipeline
The content processing pipeline will involve three main stages: **ingestion**, **processing**, and **storage**.

#### Ingestion
- Documents will be retrieved from **MinIO** by workers based on their file type (e.g., PDF, HTML, Markdown, etc.).
- The worker will extract and submit the plain text version of the document (along with the file name) to the **OpenAPI interface** for further processing.
   
#### Processing
- The text extracted from documents will be fed into a **HuggingFace transformer model** or a similar **Small Language Model (SLM)** for text parsing, including additional summarization and metadata extraction (such as subject and description).
- For non-text media (e.g., images, videos), relevant processing tools like **OCR** (for images) or **Voice2Text** (for videos) will be used to generate transcriptions.

#### Storage
- The processed data (including plain text, metadata, and additional information) will be stored in the PostgreSQL database, with the filename serving as the primary key.
- Tags and other categorization information will be stored in separate tables to facilitate effective search and organization.

### 6. File Processing Workers
- Separate workers will be developed for each known file type:
  - **PDF, HTML, Markdown, DOCX, ODT**: Convert to plain text and extract metadata.
  - **JPG, PNG**: Use **OCR** to convert to text and extract metadata.
  - **Video**: Use **Voice2Text** (or similar technology) to generate transcriptions.
- Each worker will submit the processed text to the **OpenAPI** interface for further processing and storage.

### 7. Implementation Details
- The **OpenAPI v2** schema will be attached to the **Mojo** server, and the system will be containerized using Docker.
- Workers will be developed to connect to **MinIO**, retrieve documents, and process them through the pipeline.
- Once all components are implemented and tested, the system will undergo comprehensive **quality assurance (QA)** to ensure functionality and performance.
   
### 8. Licensing and Compliance
- The software will be developed in compliance with **OpenChain** standards.
- A suitable **open-source software (OSS) license** will be chosen based on the project's requirements and objectives.

---

## Development Steps

1. **Create OpenAPI v2 Schema**: Define the structure for the API that will be used by all components.
    > Make sure to make a fake data provider using this schema to unblock alex
3. **Attach Schema to Mojo**: Integrate the schema into the Mojo server to expose the API.
4. **Dockerize the Application**: Containerize the entire system using Docker for consistent deployment.
5. **Move Files into MinIO**: Store all documents in MinIO for centralized access and management.
6. **Develop and Deploy Workers**:
   - Implement workers to retrieve and process different file types.
   - Create and test the first worker for processing **PDF** files.
   - Ensure that processed data is submitted to the OpenAPI interface for further processing.
7. **Implement Processing Logic**:
   - Use **HuggingFace transformers** for text-based documents.
   - Use **OCR** for image files (JPG, PNG).
   - Implement **Voice2Text** for video files.
8. **Store Processed Data**: Store the results in PostgreSQL, associating metadata with the filename for easy retrieval.
9. **Tagging and Categorization**: Add a content worker to generate and store tags for better searchability.
10. **QA and Testing**: Perform quality assurance to validate the full pipeline and correct functionality.
11. **Final Deployment**: Deploy the system and ensure its readiness for production use.

---

## File Processing Guidelines

- **PDF, HTML, Markdown, DOCX, ODT**: Convert all these formats to plain text, including the extraction of document metadata. The output will be stored in JSON format for easy parsing and querying.
- **JPG, PNG**: Use OCR to extract text from images. The text will be stored in JSON format for integration into the system.
- **Video**: Convert audio to text using **Voice2Text**. The transcribed text will be stored in JSON format.

## Conclusion

This approach ensures that the documents are efficiently ingested, processed, and stored in a structured manner, allowing for easy search and retrieval via the knowledge graph interface. All components will be developed in accordance with best practices for open-source software development and deployment.

### Timesheet (pre-reg)
* 18/11/2024 - 3 Hours (3h)
    * 2 Hours - Examining options
    * 1 Hours - Exploration
* 19/11/2024 - 3 Hours (6h)
    * 3 Hours - Foreward planning
* 20/11/2024 - 4 Hours (1d 2.5h)
    * 4 Hours - Investigation into SLM's
    * 0.5 Hours - Administration
* 21/11/2024 - 1 Hour (1d 3.5h)
    * 1 Hour - Rewriting notes to be coherent.

### Timesheet (post-reg)
* 22/11/2024 - 8 Hours (8h)
    * 2 Hours - Examining options
    * 1 Hours - Exploration
    * 3 Hours - Foreward planning
    * 2 hours - Investigation into SLM's
* 23/11/2024 - 3.5 Hours (1d 3.5h)
    * 2 hours - Investigation into SLM's
    * 0.5 Hours - Administration
    * 1 Hour - Rewriting notes to be coherent.
* 03/12/2024 - 0.5 Hours (1d 4h)
    * 0.5 - Minio technical investigation

## AOC Notes

* Create Vue front end that calls the mojo service to access data.
* Dockerise 
* Will use Vuetify as a base component library 
* Build site similar to https://nlnet.nl/project/current.html to allow users to navigate the different documents and find similar and related documents.
* Implement search to search by name or by document tags (will require search endpoint)
* Generate client side handlers for api from open-api spec

### Questions to Answer

* How will the data be structured from the API
* Do the site need to be able to handle the display of the different file outputs itself or can it just open a new tab and let the browser handle it.

### Timesheet
* 19/11/2024
    * 0.5 Hours - Examining options
    * 0.75 hours - Discussing plan with Paul on next steps
    * 1 hour - Get a docker Vue example working
    * 1.75 hours - Learning basic vue
