import os
import re
import json
import time
import pandas as pd
import requests
from rapidfuzz import process, fuzz
import google.generativeai as genai
from PIL import Image
from io import BytesIO

# --- CONFIGURATION ---
GEMINI_API_KEY = "AIzaSyDCCqNHlb1TPflGwl8aDzEu_317aTxsuqE"
GEMINI_MODEL = "gemini-2.5-flash"
DATASET_URL = "https://huggingface.co/datasets/laila-mohamed/egyptian-nutrition-dataset/resolve/main/egyptian_nutrition.csv"

class NutritionService:
    def __init__(self):
        genai.configure(api_key=GEMINI_API_KEY)
        self.model = genai.GenerativeModel(GEMINI_MODEL)
        self.df = None
        self.cols = [
            "ENERGY (Kcal)", "PROTEIN (g)", "FAT (g)", "CARBOHYDRATE (g)", 
            "SODIUM (mg)", "FIBER (g)", "CALCIUM (mg)", "WATER (g)", "ASH (g)",
            "IRON (mg)", "MAGNESIUM (mg)", "ZINC (mg)"
        ]
        self._load_dataset()

    def _load_dataset(self):
        try:
            print("[*] Loading Egyptian Nutrition Dataset...")
            self.df = pd.read_csv(DATASET_URL)
            self.df["FOOD"] = self.df["FOOD"].str.lower().str.strip()
            for col in self.cols:
                if col not in self.df.columns: self.df[col] = 0
            print("[SUCCESS] Dataset loaded.")
        except Exception as e:
            print(f"[ERROR] Dataset load failed: {e}")
            self.df = pd.DataFrame(columns=["FOOD"] + self.cols)

    def safe_generate(self, contents):
        for _ in range(3):
            try:
                res = self.model.generate_content(contents)
                if res and res.text: return res.text
            except Exception as e:
                print(f"Gemini Error: {e}")
                time.sleep(1.5)
        return ""

    def detect_food_from_image(self, image_bytes):
        prompt = """
        ACT AS A PROFESSIONAL NUTRITIONIST. Analyze the provided image with high precision.
        
        TASKS:
        1. Identify EVERY food item in the image. Be specific (e.g., 'Basmati Rice' instead of just 'Rice').
        2. Estimate the quantity based on the plate proportion (assume a standard 25cm plate).
        3. Use ONLY 'cup' for volume-based items and 'g' for solid/weight-based items.
        
        OUTPUT FORMAT (STRICT):
        [quantity] [unit] [food_name]
        
        RULES:
        - Output ONLY the list. No intro, no bullets, no markdown.
        - Use decimals for fractions (e.g., 0.5 instead of 1/2).
        - If unsure of weight, a standard portion is 150g or 1 cup.
        
        EXAMPLE:
        0.5 cup pasta
        120 g chicken breast
        0.25 cup salad
        """
        try:
            image = Image.open(BytesIO(image_bytes))
            res = self.safe_generate([prompt, image])
            print(f"AI RAW Output: {res}")
            return res.strip()
        except Exception as e:
            print(f"Detection Error: {e}")
            return ""

    def parse_food_list(self, text):
        if "NO_FOOD_DETECTED" in text.upper(): return []
        foods = []
        # Support various line separators
        lines = re.split(r'[\n\r,;]', text.lower())
        
        for line in lines:
            line = line.strip()
            if not line or len(line) < 3: continue
            
            # Remove ONLY list markers like *, -, or numbers followed by a dot (1., 2.)
            # But PRESERVE quantities like 0.5, 1.5, etc.
            line = re.sub(r'^[\*\-\s]+', '', line).strip() # Remove bullets
            line = re.sub(r'^\d+\.\s+', '', line).strip()  # Remove list numbers like "1. " but not "0.5 "
            
            # Smart Extraction Logic
            # Try to find number, then unit, then name
            qty = 1.0
            unit = "g"
            food_name = line
            
            # Find numbers (including decimals)
            nums = re.findall(r"(\d+\.?\d*)", line)
            if nums:
                qty = float(nums[0])
                # Remove the number from the line to avoid matching it as part of name
                line = line.replace(nums[0], "", 1).strip()
            
            # Find units
            unit_match = re.search(r"\b(cup|cups|g|gram|grams|ml|oz|piece|slice)\b", line, re.IGNORECASE)
            if unit_match:
                found_unit = unit_match.group(0).lower()
                unit = "cup" if "cup" in found_unit else "g"
                line = line.replace(unit_match.group(0), "", 1).strip()
            
            # The rest is the food name
            food_name = line.strip()
            if not food_name: food_name = "unknown food"
            
            foods.append({"quantity": round(qty, 2), "unit": unit, "food": food_name})
            
        return foods

    def convert_to_grams(self, q, unit, food_name=""):
        densities = {"cup": 180, "g": 1, "grams": 1, "piece": 150}
        return q * densities.get(unit.lower(), 100)

    def analyze_meal(self, food_list):
        results = []
        total = {c: 0 for c in self.cols}
        for item in food_list:
            qty, unit, name = float(item["quantity"]), item["unit"].lower(), item["food"]
            grams = self.convert_to_grams(qty, unit, name)
            entry = {"food": name, "quantity": qty, "unit": unit, "weight_g": grams}
            
            # Data source chain: Try DB, then OFF, then AI
            data = self._find_in_db(name)
            if data is None:
                data = self._find_in_off(name)
            if data is None:
                data = self._estimate_with_ai(name, 100)
            
            if data is not None:
                # Convert to dict if it's a pandas Series
                if hasattr(data, "to_dict"): data = data.to_dict()
                
                factor = grams / 100
                for c in self.cols:
                    val = float(data.get(c, 0) or 0) * factor
                    entry[c] = round(val, 2)
                    total[c] += val
            results.append(entry)
            
        return {
            "ingredients": results,
            "total": {k: round(v, 2) for k, v in total.items()},
            "health_score": self._calc_score(total)
        }

    def _find_in_db(self, name):
        if self.df is None or self.df.empty: return None
        match = process.extractOne(name, self.df["FOOD"], scorer=fuzz.WRatio)
        if match and match[1] > 80:
            return self.df[self.df["FOOD"] == match[0]].iloc[0]
        return None

    def _find_in_off(self, name):
        try:
            url = f"https://world.openfoodfacts.org/cgi/search.pl?search_terms={name}&action=process&json=1&page_size=1"
            r = requests.get(url, timeout=5).json()
            if not r.get("products"): return None
            nutr = r["products"][0].get("nutriments", {})
            return {
                "ENERGY (Kcal)": nutr.get("energy-kcal_100g", 0),
                "PROTEIN (g)": nutr.get("proteins_100g", 0),
                "FAT (g)": nutr.get("fat_100g", 0),
                "CARBOHYDRATE (g)": nutr.get("carbohydrates_100g", 0),
                "SODIUM (mg)": nutr.get("sodium_100g", 0),
                "FIBER (g)": nutr.get("fiber_100g", 0),
                "CALCIUM (mg)": nutr.get("calcium_100g", 0),
                "IRON (mg)": nutr.get("iron_100g", 0)
            }
        except: return None

    def _estimate_with_ai(self, name, grams):
        prompt = f"Provide nutrition per {grams}g of '{name}'. Return ONLY valid JSON: {json.dumps({c: 0 for c in self.cols})}"
        res = self.safe_generate(prompt)
        try:
            return json.loads(re.sub(r'```json|```', '', res).strip())
        except: return {c: 0 for c in self.cols}

    def _calc_score(self, t):
        s = 70
        if t["PROTEIN (g)"] > 20: s += 10
        if t["FIBER (g)"] > 5: s += 10
        if t["FAT (g)"] > 30: s -= 15
        if t["SODIUM (mg)"] > 1000: s -= 15
        if t["ENERGY (Kcal)"] > 800: s -= 10
        return max(0, min(100, s))

    def chat(self, question, meal_data):
        prompt = f"""
        NUTRITIONIST AI. Context: {json.dumps(meal_data['total'])}
        STRICT RULES:
        1. Be extremely concise and "to the point".
        2. Use bullet points for advice or alternatives.
        3. Structure your response with clear, short headings if needed.
        4. Provide medical-grade nutrition advice only.
        5. USE ONLY EMOJIS for status: ✅ (instead of YES), ❌ (instead of NO), ⚠️ (instead of CAUTION).
        6. Wrap key terms or headings in **bold** for emphasis.
        Question: {question}
        """
        res = self.safe_generate(prompt)
        # Fallback replacement to ensure symbols appear
        res = res.replace("CAUTION:", "⚠️").replace("CAUTION", "⚠️")
        res = res.replace("YES:", "✅").replace("YES", "✅")
        res = res.replace("NO:", "❌").replace("NO", "❌")
        return res

nutrition_service = NutritionService()
