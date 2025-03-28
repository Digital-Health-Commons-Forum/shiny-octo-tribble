import os
import sys
import json
from pathlib import Path
from typing import Dict, Any, List, Optional
import magic  # for file type detection
from datetime import datetime
import logging
from tqdm import tqdm
import hashlib
import base64

# Import and configure Tesseract
try:
    import pytesseract
    pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
except ImportError:
    logging.warning("pytesseract not installed - image processing will be disabled")
    pytesseract = None

# Configure logging
import warnings
warnings.filterwarnings('ignore', message='.*nltk.*')

# Create log directory if it doesn't exist
log_dir = Path("log")
log_dir.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_dir / 'processing.log'),
        logging.StreamHandler()
    ]
)

# File processing imports
import fitz  # PyMuPDF for PDFs
import docx  # python-docx for Word documents
import markdown
import pptx  # python-pptx for PowerPoint
import pandas as pd  # for Excel files
from PIL import Image
import pytesseract  # for image text extraction
from bs4 import BeautifulSoup
import mimetypes

# NLP imports
try:
    import spacy
    import nltk
    from nltk.tokenize import sent_tokenize
    from nltk.corpus import stopwords
    from nltk.tag import pos_tag
    from collections import Counter
    import re

    # Download required NLTK data silently
    class NLTKDownloadSilencer:
        def __enter__(self):
            self._original_stderr = sys.stderr
            sys.stderr = open(os.devnull, 'w')
            
        def __exit__(self, exc_type, exc_val, exc_tb):
            sys.stderr.close()
            sys.stderr = self._original_stderr

    with NLTKDownloadSilencer():
        nltk.download('punkt')
        nltk.download('averaged_perceptron_tagger')
        nltk.download('stopwords')
        nltk.download('maxent_ne_chunker')
        nltk.download('words')

    # Load English language model for spaCy
    try:
        nlp = spacy.load("en_core_web_sm")
        nlp.max_length = 2000000  # Increase max length to 2M characters
    except OSError:
        logging.warning("Downloading spaCy English language model...")
        os.system("python -m spacy download en_core_web_sm")
        nlp = spacy.load("en_core_web_sm")
        nlp.max_length = 2000000
except ImportError as e:
    logging.error(f"NLP dependencies not available: {str(e)}")
    spacy = None
    nltk = None
    nlp = None

# List of supported file types
SUPPORTED_TYPES = {
    'application/pdf': 'pdf',
    'application/msword': 'doc',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'docx',
    'text/markdown': 'md',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'pptx',
    'application/vnd.ms-excel': 'xls',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'xlsx',
    'image/png': 'png',
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'text/plain': 'txt'
}

class DocumentProcessor:
    def __init__(self, input_dir: str, output_dir: str):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.mime = magic.Magic(mime=True)
        # Use the global nlp instance
        self.nlp = nlp
        
    def is_supported_file_type(self, file_path: Path) -> bool:
        """Check if the file type is supported."""
        try:
            # Special handling for markdown files
            if file_path.suffix.lower() == '.md':
                return True
                
            mime_type = self.mime.from_file(str(file_path))
            logging.debug(f"File {file_path} has mime type: {mime_type}")
            return mime_type in SUPPORTED_TYPES
        except Exception as e:
            logging.warning(f"Error checking file type for {file_path}: {str(e)}")
            return False

    def extract_text_from_pdf(self, file_path: str) -> str:
        """Extract text from PDF files with chunking for large files."""
        try:
            doc = fitz.open(file_path)
            text = ""
            for page in doc:
                text += page.get_text()
                if len(text) > 1000000:  # If text gets too large, process in chunks
                    break
            doc.close()
            return text
        except Exception as e:
            logging.error(f"Error extracting text from PDF {file_path}: {str(e)}")
            return ""

    def extract_text_from_docx(self, file_path: str) -> str:
        """Extract text from DOCX files."""
        try:
            doc = docx.Document(file_path)
            return "\n".join([paragraph.text for paragraph in doc.paragraphs])
        except Exception as e:
            logging.error(f"Error extracting text from DOCX {file_path}: {str(e)}")
            return ""

    def extract_text_from_markdown(self, file_path: str) -> str:
        """Extract text from Markdown files."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                html = markdown.markdown(content)
                soup = BeautifulSoup(html, 'html.parser')
                return soup.get_text()
        except Exception as e:
            logging.error(f"Error extracting text from Markdown {file_path}: {str(e)}")
            return ""

    def extract_text_from_pptx(self, file_path: str) -> str:
        """Extract text from PPTX files."""
        try:
            prs = pptx.Presentation(file_path)
            text = []
            for slide in prs.slides:
                for shape in slide.shapes:
                    if hasattr(shape, "text"):
                        text.append(shape.text)
            return "\n".join(text)
        except Exception as e:
            logging.error(f"Error extracting text from PPTX {file_path}: {str(e)}")
            return ""

    def extract_text_from_excel(self, file_path: str) -> str:
        """Extract text from Excel files."""
        try:
            df = pd.read_excel(file_path)
            return df.to_string()
        except Exception as e:
            logging.error(f"Error extracting text from Excel {file_path}: {str(e)}")
            return ""

    def extract_text_from_image(self, file_path: str) -> str:
        """Extract text from images using Tesseract OCR."""
        if pytesseract is None:
            logging.error(f"Cannot process image {file_path}: pytesseract is not installed")
            return ""
            
        try:
            image = Image.open(file_path)
            text = pytesseract.image_to_string(image)
            return text
        except Exception as e:
            logging.error(f"Error extracting text from image {file_path}: {str(e)}")
            return ""

    def generate_identifier(self, file_size: int, file_name: str, modified_time: str) -> str:
        """Generate a unique identifier using SHA256 and base64 encoding."""
        # Combine the fields with a separator
        combined = f"{file_size}|{file_name}|{modified_time}"
        # Create SHA256 hash
        sha256_hash = hashlib.sha256(combined.encode('utf-8')).digest()
        # Convert to base64 and remove padding
        return base64.b64encode(sha256_hash).decode('utf-8').rstrip('=')

    def get_file_metadata(self, file_path: Path) -> Dict[str, Any]:
        """Get metadata for a file."""
        try:
            # Get the full relative path and normalize it to use forward slashes
            relative_path = file_path.relative_to(self.input_dir)
            normalized_path = str(relative_path).replace('\\', '/')
            
            # Get file stats
            stat = file_path.stat()
            file_size = stat.st_size
            file_name = file_path.name
            modified_time = datetime.fromtimestamp(stat.st_mtime).isoformat()
            
            return {
                'file_name': file_name,
                'file_path': normalized_path,
                'file_size': file_size,
                'created_time': datetime.fromtimestamp(stat.st_ctime).isoformat(),
                'modified_time': modified_time,
                'file_type': self.mime.from_file(str(file_path))
            }
        except Exception as e:
            logging.error(f"Error getting metadata for {file_path}: {str(e)}")
            # Return basic metadata even if there's an error
            return {
                'file_name': file_path.name,
                'file_path': str(file_path.relative_to(self.input_dir)).replace('\\', '/'),
                'file_type': self.mime.from_file(str(file_path))
            }

    def extract_summary(self, text: str) -> str:
        """Extract a summary using sentence scoring."""
        if nltk is None:
            logging.error("NLTK is not available for text summarization")
            return "Text summarization not available - NLTK not installed"
            
        try:
            sentences = sent_tokenize(text)
            if not sentences:
                return "No text content found."
            
            # Score sentences based on word frequency
            word_freq = Counter()
            for sentence in sentences:
                words = nltk.word_tokenize(sentence.lower())
                word_freq.update(words)
            
            # Get top 3 sentences
            sentence_scores = {}
            for sentence in sentences:
                words = nltk.word_tokenize(sentence.lower())
                score = sum(word_freq[word] for word in words)
                sentence_scores[sentence] = score
            
            top_sentences = sorted(sentence_scores.items(), key=lambda x: x[1], reverse=True)[:3]
            return " ".join(sentence for sentence, _ in top_sentences)
        except Exception as e:
            logging.error(f"Error extracting summary: {str(e)}")
            return "Error extracting summary"

    def extract_description(self, text: str) -> str:
        """Extract a more detailed description using key phrases."""
        if self.nlp is None:
            logging.error("spaCy model is not available for description extraction")
            return "Description extraction not available - spaCy not installed"
            
        try:
            # Process text in chunks if it's too long
            if len(text) > 1000000:
                text = text[:1000000]
            
            doc = self.nlp(text)
            key_phrases = []
            
            # Extract noun phrases
            for chunk in doc.noun_chunks:
                if len(chunk.text.split()) >= 2:  # Only keep multi-word phrases
                    key_phrases.append(chunk.text)
            
            # Extract named entities
            for ent in doc.ents:
                if ent.label_ in ['ORG', 'GPE', 'PERSON', 'DATE', 'TIME']:
                    key_phrases.append(ent.text)
            
            return "Key topics: " + ", ".join(set(key_phrases[:10]))  # Limit to top 10 phrases
        except Exception as e:
            logging.error(f"Error extracting description: {str(e)}")
            return "Error extracting description"

    def extract_author(self, text: str) -> str:
        """Extract author information using NLP and regex patterns."""
        if self.nlp is None:
            logging.error("spaCy model is not available for author extraction")
            return "Author extraction not available - spaCy not installed"
            
        try:
            # Clean up text by removing newlines and extra whitespace
            text = ' '.join(text.split())
            
            # Remove common metadata patterns
            text = re.sub(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', '', text)  # Remove emails
            text = re.sub(r'\d{4}', '', text)  # Remove years
            text = re.sub(r'•|○|●|■|□|▪|▫', '', text)  # Remove bullet points
            
            # Common author patterns
            author_patterns = [
                r'(?:Author|Written by|By|Prepared by|Developed by|Created by|Contributor):\s*([A-Za-z\s]+(?:[A-Za-z\s]+)*)',
                r'([A-Za-z\s]+(?:[A-Za-z\s]+)*)\s*(?:Author|Writer|Contributor)',
                r'Contact:\s*([A-Za-z\s]+(?:[A-Za-z\s]+)*)',
                r'Email:\s*[^@\s]+@[^@\s]+\.[^@\s]+\s*([A-Za-z\s]+(?:[A-Za-z\s]+)*)'
            ]
            
            # Try regex patterns first
            for pattern in author_patterns:
                match = re.search(pattern, text)
                if match:
                    author = match.group(1).strip()
                    if len(author.split()) >= 2:  # Must have at least first and last name
                        return author
            
            # If no regex match, try named entity recognition
            doc = self.nlp(text)
            potential_authors = []
            
            # Look for PERSON entities with titles
            for ent in doc.ents:
                if ent.label_ == 'PERSON':
                    # Get surrounding context
                    start = max(0, ent.start_char - 50)
                    end = min(len(text), ent.end_char + 50)
                    context = text[start:end]
                    
                    # Check for common titles
                    titles = ['Dr\.', 'Mr\.', 'Mrs\.', 'Ms\.', 'Professor', 'Prof\.', 'Director', 'Manager', 'Lead', 'Head']
                    if any(re.search(title, context) for title in titles):
                        potential_authors.append(ent.text.strip())
            
            if potential_authors:
                return potential_authors[0]
            
            return "Author not found"
        except Exception as e:
            logging.error(f"Error extracting author: {str(e)}")
            return "Error extracting author"

    def extract_names(self, text: str) -> List[str]:
        """Extract names mentioned in the text."""
        if self.nlp is None:
            logging.error("spaCy model is not available for name extraction")
            return []
            
        try:
            # Clean up text by removing newlines and extra whitespace
            text = ' '.join(text.split())
            
            # Remove common metadata patterns
            text = re.sub(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', '', text)  # Remove emails
            text = re.sub(r'\d{4}', '', text)  # Remove years
            text = re.sub(r'•|○|●|■|□|▪|▫', '', text)  # Remove bullet points
            
            # Process text in chunks if it's too long
            if len(text) > 1000000:
                text = text[:1000000]
            
            doc = self.nlp(text)
            names = set()
            
            # Extract PERSON entities
            for ent in doc.ents:
                if ent.label_ == 'PERSON':
                    # Clean up the name
                    name = ' '.join(ent.text.split())
                    if name.strip():
                        # Only keep names that look like real names (at least two words)
                        if len(name.split()) >= 2 and not re.match(r'^[A-Z\s]{2,}$', name):
                            names.add(name.strip())
            
            return sorted(list(names))
        except Exception as e:
            logging.error(f"Error extracting names: {str(e)}")
            return []

    def extract_tags(self, text: str) -> List[str]:
        """Extract relevant tags using NLP."""
        if self.nlp is None:
            logging.error("spaCy model is not available for tag extraction")
            return []
            
        try:
            # Process text in chunks if it's too long
            if len(text) > 1000000:
                text = text[:1000000]
            
            # Clean up text by removing newlines and extra whitespace
            text = ' '.join(text.split())
            
            doc = self.nlp(text)
            tags = set()
            
            # Extract noun phrases as potential tags
            for chunk in doc.noun_chunks:
                # Clean up the chunk text
                chunk_text = ' '.join(chunk.text.split())
                if len(chunk_text.split()) <= 3 and chunk_text.strip():  # Only keep short phrases
                    tags.add(chunk_text.lower().strip())
            
            # Extract named entities
            for ent in doc.ents:
                if ent.label_ in ['ORG', 'GPE', 'PERSON', 'DATE', 'TIME']:
                    # Clean up entity text
                    ent_text = ' '.join(ent.text.split())
                    if ent_text.strip():
                        tags.add(ent_text.lower().strip())
            
            # Add common healthcare-related terms if found
            healthcare_terms = {
                'diabetes', 'cancer', 'heart', 'blood', 'treatment', 'patient',
                'doctor', 'hospital', 'clinic', 'medicine', 'disease', 'health',
                'medical', 'surgery', 'therapy', 'diagnosis', 'prescription'
            }
            
            text_lower = text.lower()
            for term in healthcare_terms:
                if term in text_lower:
                    tags.add(term)
            
            # Clean up any remaining tags with newlines or extra whitespace
            cleaned_tags = {tag.strip() for tag in tags if tag.strip()}
            return sorted(list(cleaned_tags))
        except Exception as e:
            logging.error(f"Error extracting tags: {str(e)}")
            return []

    def analyze_text(self, text: str, file_path: str) -> Dict[str, Any]:
        """Analyze text using local NLP processing."""
        try:
            return {
                "summary": self.extract_summary(text),
                "description": self.extract_description(text),
                "author": self.extract_author(text),
                "names_mentioned": self.extract_names(text),
                "tags": self.extract_tags(text)
            }
        except Exception as e:
            logging.error(f"Error analyzing text for {file_path}: {str(e)}")
            return {
                "summary": "Error analyzing document",
                "description": f"Error: {str(e)}",
                "author": "Unknown",
                "names_mentioned": [],
                "tags": []
            }

    def process_file(self, file_path: str) -> Dict[str, Any]:
        """Process a single file and return extracted information."""
        try:
            file_path = Path(file_path)
            logging.info(f"Checking file type for: {file_path}")
            if not self.is_supported_file_type(file_path):
                logging.warning(f"Unsupported file type: {file_path}")
                return None

            # Extract text based on file type
            text = ""
            logging.info(f"Extracting text from: {file_path}")
            if file_path.suffix.lower() == '.pdf':
                text = self.extract_text_from_pdf(str(file_path))
            elif file_path.suffix.lower() == '.docx':
                text = self.extract_text_from_docx(str(file_path))
            elif file_path.suffix.lower() == '.md':
                text = self.extract_text_from_markdown(str(file_path))
            elif file_path.suffix.lower() == '.pptx':
                text = self.extract_text_from_pptx(str(file_path))
            elif file_path.suffix.lower() in ['.xlsx', '.xls']:
                text = self.extract_text_from_excel(str(file_path))
            elif file_path.suffix.lower() in ['.png', '.jpg', '.jpeg']:
                text = self.extract_text_from_image(str(file_path))
            elif file_path.suffix.lower() == '.txt':
                with open(file_path, 'r', encoding='utf-8') as f:
                    text = f.read()

            if not text:
                logging.warning(f"No text extracted from {file_path}")
                return None

            # Get metadata and generate identifier
            metadata = self.get_file_metadata(file_path)
            identifier = self.generate_identifier(
                metadata['file_size'],
                metadata['file_name'],
                metadata['modified_time']
            )
            
            # For infographics and image-based content, just return the extracted text
            if 'infographic' in file_path.name.lower() or file_path.suffix.lower() in ['.png', '.jpg', '.jpeg']:
                result = {
                    '_stash': {
                        'identifier': identifier,
                        'state': 1
                    },
                    'metadata': metadata,
                    'extracted_text': text,
                    'content_type': 'infographic'
                }
            else:
                # For regular documents, perform NLP analysis
                result = {
                    '_stash': {
                        'identifier': identifier,
                        'state': 1
                    },
                    'metadata': metadata,
                    'summary': self.extract_summary(text),
                    'description': self.extract_description(text),
                    'author': self.extract_author(text),
                    'names_mentioned': self.extract_names(text),
                    'tags': self.extract_tags(text),
                    'content_type': 'document'
                }

            # Save results maintaining the full directory structure
            relative_path = file_path.relative_to(self.input_dir)
            output_file = self.output_dir / relative_path.parent / f"{file_path.stem}.json"
            output_file.parent.mkdir(parents=True, exist_ok=True)
            logging.info(f"Saving results to: {output_file}")
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2, ensure_ascii=False)

            return result
        except Exception as e:
            logging.error(f"Error processing {file_path}: {str(e)}")
            return None

    def process_directory(self, directory: Path) -> List[Dict[str, Any]]:
        """Process all files in a directory and its subdirectories."""
        results = []
        stats = {"ok": 0, "error": 0, "unsupported": 0}
        
        # Get all files in directory and subdirectories
        files = [f for f in directory.rglob('*') if f.is_file()]
        total_files = len(files)
        
        # Process files with progress bar
        with tqdm(total=total_files, desc="Processing files") as pbar:
            for file_path in files:
                try:
                    # Skip files that start with . or _
                    if file_path.name.startswith(('.', '_')):
                        continue
                        
                    # Process the file
                    pbar.set_description(f"Processing {file_path.name}")
                    result = self.process_file(str(file_path))
                    
                    if result:
                        results.append(result)
                        stats[result["state"]] = stats.get(result["state"], 0) + 1
                        
                    pbar.set_postfix(ok=stats["ok"], error=stats["error"], unsupported=stats["unsupported"])
                    pbar.update(1)
                        
                except Exception as e:
                    logging.error(f"Error processing {file_path}: {str(e)}")
                    stats["error"] += 1
                    continue
        
        # Save combined results
        if results:
            combined_file = self.output_dir / 'combined_analysis.json'
            with open(combined_file, 'w', encoding='utf-8') as f:
                json.dump(results, f, indent=2, ensure_ascii=False)
        
        logging.info(f"Processing complete. Stats: {stats}")
        return results

def main():
    """Main entry point for the script."""
    try:
        if len(sys.argv) != 2:
            print("Usage: python poc.py <file_path>")
            sys.exit(1)

        file_path = Path(sys.argv[1])
        # Use the root input directory as the base for relative paths
        input_dir = Path("asset/input")
        # Create output directory mirroring input structure
        output_dir = Path("asset/output")
        
        processor = DocumentProcessor(str(input_dir), str(output_dir))
        result = processor.process_file(str(file_path))
        
        if result:
            print(f"Successfully processed {file_path}")
        else:
            print(f"Failed to process {file_path}")
            sys.exit(1)

    except Exception as e:
        logging.error(f"Error in main: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 