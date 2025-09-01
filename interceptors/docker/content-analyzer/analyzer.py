import json
import sys
import logging
import os
from typing import Dict, Any
from datetime import datetime
import re

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ContentAnalyzer:
    def __init__(self):
        self.analysis_models = os.getenv('ANALYSIS_MODEL', 'sentiment,quality').split(',')
        self.confidence_threshold = float(os.getenv('CONFIDENCE_THRESHOLD', '0.8'))
        
        # Quality assessment patterns
        self.quality_indicators = {
            'high_quality': [
                re.compile(r'\b(research|study|analysis|official|verified)\b', re.IGNORECASE),
                re.compile(r'\b(peer-reviewed|published|academic)\b', re.IGNORECASE),
            ],
            'low_quality': [
                re.compile(r'\b(rumors?|gossip|allegedly)\b', re.IGNORECASE),
                re.compile(r'\b(click-?bait|sensational)\b', re.IGNORECASE),
            ]
        }
    
    def analyze(self, response_data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            # Extract content
            content = self._extract_content(response_data)
            if not content:
                return self._create_analysis_result("No content to analyze", {})
            
            results = {}
            
            # Run requested analyses
            if 'sentiment' in self.analysis_models:
                results['sentiment'] = self._analyze_sentiment(content)
                
            if 'quality' in self.analysis_models:
                results['quality'] = self._analyze_quality(content)
            
            # Generate overall assessment
            overall_score = self._calculate_overall_score(results)
            
            return self._create_analysis_result("Analysis complete", results, overall_score)
            
        except Exception as e:
            logger.error(f"Content analysis failed: {e}")
            return self._create_analysis_result(f"Analysis error: {str(e)}", {}, 0.0)
    
    def _extract_content(self, response_data: Dict[str, Any]) -> str:
        content_list = response_data.get('result', {}).get('content', [])
        
        full_content = ""
        for item in content_list:
            if item.get('type') == 'text' and 'text' in item:
                full_content += item['text'] + "\n"
                
        return full_content.strip()
    
    def _analyze_sentiment(self, content: str) -> Dict[str, Any]:
        # Simple sentiment analysis
        positive_words = ['good', 'great', 'excellent', 'amazing', 'wonderful', 'fantastic']
        negative_words = ['bad', 'terrible', 'awful', 'horrible', 'disappointing']
        
        content_lower = content.lower()
        positive_count = sum(1 for word in positive_words if word in content_lower)
        negative_count = sum(1 for word in negative_words if word in content_lower)
        
        if positive_count > negative_count:
            sentiment = "positive"
            polarity = 0.5 + (positive_count - negative_count) * 0.1
        elif negative_count > positive_count:
            sentiment = "negative"  
            polarity = -0.5 - (negative_count - positive_count) * 0.1
        else:
            sentiment = "neutral"
            polarity = 0.0
        
        polarity = max(-1.0, min(1.0, polarity))  # Clamp to [-1, 1]
        
        return {
            'sentiment': sentiment,
            'polarity': polarity,
            'confidence': abs(polarity) if abs(polarity) > 0.1 else 0.5
        }
    
    def _analyze_quality(self, content: str) -> Dict[str, Any]:
        try:
            quality_scores = {}
            
            # Pattern-based quality indicators
            for category, patterns in self.quality_indicators.items():
                matches = sum(1 for pattern in patterns if pattern.search(content))
                quality_scores[category] = matches
            
            # Additional quality metrics
            word_count = len(content.split())
            sentence_count = len([s for s in content.split('.') if s.strip()])
            avg_sentence_length = word_count / max(sentence_count, 1)
            
            # Calculate overall quality score
            high_quality_bonus = quality_scores.get('high_quality', 0) * 0.3
            low_quality_penalty = quality_scores.get('low_quality', 0) * -0.2
            length_bonus = min(0.2, word_count / 1000)
            
            overall_quality = max(0.0, min(1.0, 0.5 + high_quality_bonus + low_quality_penalty + length_bonus))
            
            return {
                'overall_score': overall_quality,
                'word_count': word_count,
                'sentence_count': sentence_count,
                'avg_sentence_length': avg_sentence_length,
                'quality_indicators': quality_scores,
                'assessment': 'high' if overall_quality > 0.7 else 'medium' if overall_quality > 0.4 else 'low'
            }
            
        except Exception as e:
            logger.error(f"Quality analysis failed: {e}")
            return {'overall_score': 0.5, 'assessment': 'unknown', 'error': str(e)}
    
    def _calculate_overall_score(self, results: Dict[str, Any]) -> float:
        scores = []
        
        # Quality score (weighted heavily)
        if 'quality' in results:
            scores.append(results['quality'].get('overall_score', 0.5) * 0.7)
        
        # Sentiment score (positive is good)
        if 'sentiment' in results:
            sentiment_score = (results['sentiment'].get('polarity', 0) + 1) / 2
            scores.append(sentiment_score * 0.3)
        
        return sum(scores) if scores else 0.5
    
    def _create_analysis_result(self, message: str, results: Dict[str, Any], overall_score: float = 0.5) -> Dict[str, Any]:
        return {
            'timestamp': datetime.utcnow().isoformat(),
            'message': message,
            'overall_score': overall_score,
            'results': results,
            'models_used': self.analysis_models,
            'confidence_threshold': self.confidence_threshold,
            'recommendation': 'approve' if overall_score > self.confidence_threshold else 'review'
        }

def main():
    if len(sys.argv) < 2:
        print("Usage: python analyzer.py <analyze|help>", file=sys.stderr)
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "help":
        print("Content Analyzer Container Interceptor")
        print("Commands:")
        print("  analyze - Analyze JSON response from stdin")
        sys.exit(0)
    
    if command != "analyze":
        print(f"Unknown command: {command}", file=sys.stderr)
        sys.exit(1)
    
    try:
        # Read JSON response from stdin
        response_json = sys.stdin.read()
        response_data = json.loads(response_json)
        
        # Initialize analyzer
        analyzer = ContentAnalyzer()
        
        # Perform analysis
        analysis_result = analyzer.analyze(response_data)
        
        # Add analysis results to the response
        if 'result' not in response_data:
            response_data['result'] = {}
        
        response_data['result']['content_analysis'] = analysis_result
        
        # Output enhanced response
        print(json.dumps(response_data, indent=2))
        
        # Log to stderr for debugging
        logger.info(f"Content analysis complete: score={analysis_result['overall_score']:.2f}")
        
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON input: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Analysis failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
