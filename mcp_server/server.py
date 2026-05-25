"""
MCP Educational Server - edu-mcp-server
Implements Model Context Protocol (MCP) for educational curriculum design.
Demonstrates: Resources, Prompts, Tools primitives over Stdio transport.

AI Provider Configuration (set via environment variables):
  AI_PROVIDER   = anthropic | openai | gemini | deepseek | groq | ollama | openai_compatible
                  Default: anthropic (if ANTHROPIC_API_KEY is set)
                           openai    (if OPENAI_API_KEY is set)
                           gemini    (if GEMINI_API_KEY is set)
                           deepseek  (if DEEPSEEK_API_KEY is set)
                           groq      (if GROQ_API_KEY is set)
  AI_MODEL      = override the default model for any provider
  AI_API_KEY    = API key (used for openai_compatible provider)
  AI_BASE_URL   = custom base URL (used for openai_compatible provider)

Provider defaults:
  anthropic        → claude-sonnet-4-6           (ANTHROPIC_API_KEY)
  openai           → gpt-4o                      (OPENAI_API_KEY)
  gemini           → gemini-2.0-flash            (GEMINI_API_KEY)
  deepseek         → deepseek-chat               (DEEPSEEK_API_KEY)
  groq             → llama-3.1-8b-instant        (GROQ_API_KEY)
  ollama           → llama3.2 (no key needed, local)
  openai_compatible→ set AI_BASE_URL + AI_API_KEY + AI_MODEL
"""

import asyncio
import json
import os
import datetime
import uuid
from pathlib import Path

import mcp.types as types
from mcp.server import Server
from mcp.server.models import InitializationOptions
from mcp.server.stdio import stdio_server
from mcp.server import NotificationOptions

# ─── AI Provider Configuration ───────────────────────────────────────────────

# Each entry: (api_key_env_var, base_url, default_model)
# api_key_env_var is resolved at call time so env vars set before process start are used.
_PROVIDERS = {
    "anthropic":         ("ANTHROPIC_API_KEY",  None,                                                            "claude-sonnet-4-6"),
    "openai":            ("OPENAI_API_KEY",      None,                                                            "gpt-4o"),
    "gemini":            ("GEMINI_API_KEY",      "https://generativelanguage.googleapis.com/v1beta/openai/",     "gemini-2.0-flash"),
    "deepseek":          ("DEEPSEEK_API_KEY",    "https://api.deepseek.com",                                     "deepseek-chat"),
    "groq":              ("GROQ_API_KEY",        "https://api.groq.com/openai/v1",                               "llama-3.1-8b-instant"),
    "ollama":            (None,                  "http://localhost:11434/v1",                                     "llama3.2"),
    "openai_compatible": ("AI_API_KEY",          None,                                                            "gpt-4o"),
}

def _detect_provider() -> str:
    """Auto-detect active provider. Explicit AI_PROVIDER wins; else first key found."""
    explicit = os.environ.get("AI_PROVIDER", "").strip().lower()
    if explicit in _PROVIDERS:
        return explicit
    for provider, (key_env, _, _) in _PROVIDERS.items():
        if provider in ("ollama", "openai_compatible"):
            continue
        if key_env and os.environ.get(key_env, "").strip():
            return provider
    return ""

def _active_provider() -> tuple[str, str, str, str]:
    """Returns (name, api_key, base_url, model) — all resolved from env at call time."""
    name = _detect_provider()
    if not name:
        return ("", "", "", "")
    key_env, base_url, default_model = _PROVIDERS[name]
    api_key = os.environ.get(key_env, "ollama") if key_env else "ollama"
    # openai_compatible: base_url comes from env
    if name == "openai_compatible":
        base_url = os.environ.get("AI_BASE_URL", "")
    model = os.environ.get("AI_MODEL", default_model)
    return (name, api_key, base_url, model)

async def _call_ai(prompt_text: str, max_tokens: int = 2048) -> str | None:
    """
    Call the configured AI provider with prompt_text.
    Returns the text response, or None if no provider is configured.
    Supports: Anthropic, OpenAI, Gemini, DeepSeek, Groq, Ollama, any OpenAI-compatible API.
    """
    provider, api_key, base_url, model = _active_provider()
    if not provider:
        return None

    try:
        if provider == "anthropic":
            import anthropic as _anthropic
            client = _anthropic.Anthropic(api_key=api_key)
            response = client.messages.create(
                model=model,
                max_tokens=max_tokens,
                messages=[{"role": "user", "content": prompt_text}],
            )
            return response.content[0].text

        else:
            # All other providers use the OpenAI-compatible chat completions API
            from openai import OpenAI
            kwargs = {"api_key": api_key}
            if base_url:
                kwargs["base_url"] = base_url
            client = OpenAI(**kwargs)
            response = client.chat.completions.create(
                model=model,
                max_tokens=max_tokens,
                messages=[{"role": "user", "content": prompt_text}],
            )
            return response.choices[0].message.content

    except Exception as e:
        import sys
        print(f"[AI] {provider} error: {e}", file=sys.stderr)
        return None

# ─── Chapter Content Database ────────────────────────────────────────────────

CHAPTER_DB = {
    # ── Grade 10 Physics ──────────────────────────────────────────────────────
    "phys_10_01": {
        "title": "Light – Reflection and Refraction",
        "subject": "Physics", "grade": 10,
        "concepts": ["Laws of Reflection", "Refraction", "Snell's Law", "Mirror Formula", "Lens Formula"],
        "key_formulas": [
            "Mirror Formula: 1/f = 1/v + 1/u",
            "Lens Formula:   1/f = 1/v − 1/u",
            "Snell's Law:    n₁·sin θ₁ = n₂·sin θ₂",
            "Magnification:  m = h′/h = −v/u",
        ],
        "quiz": [
            {"id":"q1","question":"According to the Laws of Reflection, the angle of incidence is:","options":["Greater than angle of reflection","Equal to angle of reflection","Less than angle of reflection","Unrelated to angle of reflection"],"correctAnswerIndex":1,"explanation":"The first law of reflection states that the angle of incidence always equals the angle of reflection, measured from the normal."},
            {"id":"q2","question":"When light travels from a denser medium to a rarer medium at an angle beyond the critical angle, the phenomenon is called:","options":["Refraction","Dispersion","Total Internal Reflection","Diffraction"],"correctAnswerIndex":2,"explanation":"Total Internal Reflection occurs when the angle of incidence exceeds the critical angle while moving from denser to rarer medium."},
            {"id":"q3","question":"A concave mirror with focal length 15 cm forms an image at 30 cm. Where is the object?","options":["At 30 cm","At 10 cm","At 20 cm","At 60 cm"],"correctAnswerIndex":0,"explanation":"Using 1/f = 1/v + 1/u: 1/15 = 1/30 + 1/u → 1/u = 1/15 − 1/30 = 1/30, so u = 30 cm (object at 30 cm)."},
            {"id":"q4","question":"Which lens always forms a virtual, erect, and diminished image regardless of object position?","options":["Concave lens","Convex lens","Plano-convex lens","Bi-concave lens"],"correctAnswerIndex":0,"explanation":"A concave (diverging) lens always produces a virtual, erect and diminished image for all real object positions."},
            {"id":"q5","question":"The refractive index of glass is 1.5. What is the speed of light in glass? (c = 3×10⁸ m/s)","options":["4.5×10⁸ m/s","2×10⁸ m/s","1.5×10⁸ m/s","3×10⁸ m/s"],"correctAnswerIndex":1,"explanation":"n = c/v, so v = c/n = 3×10⁸/1.5 = 2×10⁸ m/s."},
        ],
        "resources": [
            {"id":"v1","title":"Ray Optics – Reflection & Refraction Explained","type":"video","url":"https://www.youtube.com/watch?v=9nKGkz6ZOEY","thumbnailUrl":"https://img.youtube.com/vi/9nKGkz6ZOEY/hqdefault.jpg"},
            {"id":"a1","title":"Laws of Reflection – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Reflection_(physics)","thumbnailUrl":"https://via.placeholder.com/300x150/4A90D9/FFFFFF?text=Reflection"},
            {"id":"a2","title":"Snell's Law & Refraction – Khan Academy","type":"article","url":"https://www.khanacademy.org/science/physics/geometric-optics","thumbnailUrl":"https://via.placeholder.com/300x150/1DA462/FFFFFF?text=Snell%27s+Law"},
        ],
    },
    "phys_10_02": {
        "title": "The Human Eye and the Colourful World",
        "subject": "Physics", "grade": 10,
        "concepts": ["Structure of Human Eye", "Defects of Vision", "Dispersion of Light", "Rainbow Formation"],
        "key_formulas": [
            "Power of lens: P = 1/f (in dioptres, f in metres)",
            "For myopia: concave lens (negative power)",
            "For hypermetropia: convex lens (positive power)",
        ],
        "quiz": [
            {"id":"q1","question":"Which part of the human eye controls the amount of light entering it?","options":["Cornea","Iris","Retina","Lens"],"correctAnswerIndex":1,"explanation":"The iris is a muscular diaphragm that controls the diameter of the pupil, regulating the amount of light entering the eye."},
            {"id":"q2","question":"A person cannot see distant objects clearly. Which defect does he suffer from?","options":["Hypermetropia","Presbyopia","Myopia","Astigmatism"],"correctAnswerIndex":2,"explanation":"Myopia (near-sightedness) is a defect where the image of distant objects forms in front of the retina."},
            {"id":"q3","question":"The splitting of white light into its component colours is called:","options":["Reflection","Refraction","Dispersion","Diffraction"],"correctAnswerIndex":2,"explanation":"Dispersion is the phenomenon of splitting white light into VIBGYOR (Violet, Indigo, Blue, Green, Yellow, Orange, Red) colours."},
            {"id":"q4","question":"Which colour of light is deviated the MOST during dispersion through a prism?","options":["Red","Green","Yellow","Violet"],"correctAnswerIndex":3,"explanation":"Violet light has the shortest wavelength and is deviated most by a prism. Red light is deviated the least."},
            {"id":"q5","question":"The power of a lens is −2.5 D. What type of lens is it?","options":["Convex lens","Concave lens","Plane mirror","Plano-convex lens"],"correctAnswerIndex":1,"explanation":"A negative power indicates a concave (diverging) lens. The focal length = 1/P = 1/−2.5 = −0.4 m."},
        ],
        "resources": [
            {"id":"v1","title":"Human Eye Structure & Function","type":"video","url":"https://www.youtube.com/watch?v=Gwd6e7n7OhQ","thumbnailUrl":"https://img.youtube.com/vi/Gwd6e7n7OhQ/hqdefault.jpg"},
            {"id":"a1","title":"Defects of Vision – NCERT","type":"article","url":"https://ncert.nic.in/textbook/pdf/jesc111.pdf","thumbnailUrl":"https://via.placeholder.com/300x150/E74C3C/FFFFFF?text=Human+Eye"},
            {"id":"a2","title":"Dispersion of Light – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Dispersion_(optics)","thumbnailUrl":"https://via.placeholder.com/300x150/9B59B6/FFFFFF?text=Dispersion"},
        ],
    },
    "phys_10_03": {
        "title": "Electricity",
        "subject": "Physics", "grade": 10,
        "concepts": ["Electric Potential", "Ohm's Law", "Resistance", "Series and Parallel Circuits", "Electric Power"],
        "key_formulas": [
            "Ohm's Law: V = IR",
            "Resistance in series: R_s = R₁ + R₂ + R₃",
            "Resistance in parallel: 1/R_p = 1/R₁ + 1/R₂ + 1/R₃",
            "Electric Power: P = VI = I²R = V²/R",
            "Electrical Energy: E = Pt = VIt",
        ],
        "quiz": [
            {"id":"q1","question":"Ohm's Law states that, at constant temperature, V is:","options":["Inversely proportional to I","Equal to I","Directly proportional to I","Independent of I"],"correctAnswerIndex":2,"explanation":"Ohm's Law: V = IR. At constant resistance and temperature, voltage is directly proportional to current."},
            {"id":"q2","question":"Three resistors of 2Ω, 3Ω, and 6Ω are connected in parallel. The equivalent resistance is:","options":["11 Ω","1 Ω","2 Ω","0.5 Ω"],"correctAnswerIndex":1,"explanation":"1/R = 1/2 + 1/3 + 1/6 = 3/6 + 2/6 + 1/6 = 6/6 = 1. So R = 1 Ω."},
            {"id":"q3","question":"An electric iron of resistance 40 Ω is connected to 220 V. What is the power consumed?","options":["1210 W","5.5 W","880 W","440 W"],"correctAnswerIndex":0,"explanation":"P = V²/R = 220²/40 = 48400/40 = 1210 W."},
            {"id":"q4","question":"Which component has the property of resisting the flow of electrons?","options":["Conductor","Resistor","Capacitor","Inductor"],"correctAnswerIndex":1,"explanation":"A resistor opposes the flow of electric current (electrons) in a circuit, converting electrical energy to heat."},
            {"id":"q5","question":"In a series circuit, if one bulb fuses:","options":["Only that bulb goes out","All bulbs go out","Other bulbs glow brighter","Current increases"],"correctAnswerIndex":1,"explanation":"In a series circuit, there is only one path for current. If one component breaks, the circuit is open and all components stop working."},
        ],
        "resources": [
            {"id":"v1","title":"Ohm's Law & Electric Circuits","type":"video","url":"https://www.youtube.com/watch?v=F_vLWkkNZII","thumbnailUrl":"https://img.youtube.com/vi/F_vLWkkNZII/hqdefault.jpg"},
            {"id":"a1","title":"Electric Circuits – Khan Academy","type":"article","url":"https://www.khanacademy.org/science/physics/circuits-topic","thumbnailUrl":"https://via.placeholder.com/300x150/F39C12/FFFFFF?text=Electricity"},
        ],
    },
    # ── Grade 10 Mathematics ──────────────────────────────────────────────────
    "math_10_01": {
        "title": "Real Numbers",
        "subject": "Mathematics", "grade": 10,
        "concepts": ["Euclid's Division Lemma", "Fundamental Theorem of Arithmetic", "Irrational Numbers"],
        "key_formulas": [
            "Euclid's Division Lemma: a = bq + r, where 0 ≤ r < b",
            "HCF × LCM = Product of two numbers",
        ],
        "quiz": [
            {"id":"q1","question":"According to Euclid's Division Lemma, for any two positive integers a and b, there exist unique integers q and r such that a = bq + r where:","options":["0 < r < b","0 ≤ r < b","r > b","r = b"],"correctAnswerIndex":1,"explanation":"Euclid's Division Lemma states a = bq + r where q is quotient and r is remainder, satisfying 0 ≤ r < b."},
            {"id":"q2","question":"The HCF of 96 and 404 is:","options":["4","8","12","2"],"correctAnswerIndex":0,"explanation":"Using Euclid's algorithm: 404 = 4×96 + 20; 96 = 4×20 + 16; 20 = 1×16 + 4; 16 = 4×4 + 0. HCF = 4."},
            {"id":"q3","question":"Is √2 rational or irrational?","options":["Rational","Irrational","Neither","Both"],"correctAnswerIndex":1,"explanation":"√2 cannot be expressed as p/q (where p, q are integers, q≠0). Its decimal expansion is non-terminating, non-repeating: 1.41421..."},
            {"id":"q4","question":"The prime factorization of 140 is:","options":["2² × 5 × 7","2 × 5 × 14","4 × 5 × 7","2² × 35"],"correctAnswerIndex":0,"explanation":"140 = 2 × 70 = 2 × 2 × 35 = 2 × 2 × 5 × 7 = 2² × 5 × 7. This is the unique prime factorization."},
            {"id":"q5","question":"If HCF(a,b) = 12 and LCM(a,b) = 360, and a = 60, then b is:","options":["60","72","90","120"],"correctAnswerIndex":1,"explanation":"HCF × LCM = a × b, so 12 × 360 = 60 × b → b = 4320/60 = 72."},
        ],
        "resources": [
            {"id":"v1","title":"Real Numbers – Euclid's Division Lemma","type":"video","url":"https://www.youtube.com/watch?v=C7FO3lIagxU","thumbnailUrl":"https://img.youtube.com/vi/C7FO3lIagxU/hqdefault.jpg"},
            {"id":"a1","title":"Fundamental Theorem of Arithmetic","type":"article","url":"https://en.wikipedia.org/wiki/Fundamental_theorem_of_arithmetic","thumbnailUrl":"https://via.placeholder.com/300x150/2ECC71/FFFFFF?text=Real+Numbers"},
        ],
    },
    "math_10_02": {
        "title": "Polynomials",
        "subject": "Mathematics", "grade": 10,
        "concepts": ["Zeros of Polynomials", "Division Algorithm", "Relationship between Zeros and Coefficients"],
        "key_formulas": [
            "For ax² + bx + c: Sum of zeros = −b/a, Product of zeros = c/a",
            "Division Algorithm: Dividend = Divisor × Quotient + Remainder",
        ],
        "quiz": [
            {"id":"q1","question":"The number of zeros of the polynomial p(x) = x² − 5x + 6 is:","options":["0","1","2","3"],"correctAnswerIndex":2,"explanation":"A quadratic polynomial has at most 2 zeros. x² − 5x + 6 = (x−2)(x−3), so zeros are x=2 and x=3."},
            {"id":"q2","question":"If α and β are zeros of 2x² − 5x + 3, then α + β equals:","options":["5/2","−5/2","3/2","−3/2"],"correctAnswerIndex":0,"explanation":"For ax² + bx + c, sum of zeros = −b/a = −(−5)/2 = 5/2."},
            {"id":"q3","question":"A polynomial of degree 3 is called:","options":["Linear","Quadratic","Cubic","Quartic"],"correctAnswerIndex":2,"explanation":"Polynomials by degree: degree 1 = linear, degree 2 = quadratic, degree 3 = cubic, degree 4 = quartic."},
            {"id":"q4","question":"The geometrical meaning of zeros of a polynomial p(x) is:","options":["y-intercepts of the graph","x-intercepts of the graph","Slope of the graph","Area under the graph"],"correctAnswerIndex":1,"explanation":"The zeros of a polynomial are the x-values where the graph y = p(x) crosses or touches the x-axis (x-intercepts)."},
            {"id":"q5","question":"If product of zeros of x² + 5x + k is 10, what is k?","options":["10","−10","5","−5"],"correctAnswerIndex":0,"explanation":"For x² + 5x + k, product of zeros = k/1 = k. Given product = 10, so k = 10."},
        ],
        "resources": [
            {"id":"v1","title":"Polynomials – Zeros and Coefficients","type":"video","url":"https://www.youtube.com/watch?v=LrbF28cBVGs","thumbnailUrl":"https://img.youtube.com/vi/LrbF28cBVGs/hqdefault.jpg"},
            {"id":"a1","title":"Polynomial – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Polynomial","thumbnailUrl":"https://via.placeholder.com/300x150/3498DB/FFFFFF?text=Polynomials"},
        ],
    },
    "math_10_03": {
        "title": "Quadratic Equations",
        "subject": "Mathematics", "grade": 10,
        "concepts": ["Standard Form", "Factorization Method", "Completing the Square", "Quadratic Formula", "Discriminant"],
        "key_formulas": [
            "Standard form: ax² + bx + c = 0 (a ≠ 0)",
            "Quadratic formula: x = (−b ± √(b²−4ac)) / 2a",
            "Discriminant: D = b² − 4ac",
            "D > 0: two distinct real roots | D = 0: two equal roots | D < 0: no real roots",
        ],
        "quiz": [
            {"id":"q1","question":"The discriminant of 2x² − 4x + 3 is:","options":["8","-8","40","-8"],"correctAnswerIndex":1,"explanation":"D = b² − 4ac = (−4)² − 4(2)(3) = 16 − 24 = −8. Since D < 0, the equation has no real roots."},
            {"id":"q2","question":"The roots of x² − 5x + 6 = 0 are:","options":["2 and 3","−2 and −3","1 and 6","−1 and −6"],"correctAnswerIndex":0,"explanation":"x² − 5x + 6 = (x−2)(x−3) = 0, so x = 2 or x = 3."},
            {"id":"q3","question":"If the discriminant equals zero, the quadratic equation has:","options":["No real roots","Two distinct real roots","Two equal real roots","Infinite roots"],"correctAnswerIndex":2,"explanation":"When D = b² − 4ac = 0, the formula gives x = −b/2a (once). The equation has two equal (repeated) roots."},
            {"id":"q4","question":"By quadratic formula, the roots of x² − 3x − 4 = 0 are:","options":["4 and −1","−4 and 1","3 and −1","−3 and 4"],"correctAnswerIndex":0,"explanation":"D = 9 + 16 = 25. x = (3 ± 5)/2 → x = 4 or x = −1."},
            {"id":"q5","question":"Which method gives exact irrational roots most easily?","options":["Factorisation","Graphical method","Completing the square","Trial and error"],"correctAnswerIndex":2,"explanation":"Completing the square and the quadratic formula (derived from it) always work and give exact roots, including irrational ones."},
        ],
        "resources": [
            {"id":"v1","title":"Quadratic Formula Explained","type":"video","url":"https://www.youtube.com/watch?v=i7idZfS8t8w","thumbnailUrl":"https://img.youtube.com/vi/i7idZfS8t8w/hqdefault.jpg"},
            {"id":"a1","title":"Quadratic Equation – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Quadratic_equation","thumbnailUrl":"https://via.placeholder.com/300x150/E67E22/FFFFFF?text=Quadratics"},
        ],
    },
    # ── Grade 10 Chemistry ────────────────────────────────────────────────────
    "chem_10_01": {
        "title": "Chemical Reactions and Equations",
        "subject": "Chemistry", "grade": 10,
        "concepts": ["Balancing Equations", "Types of Reactions", "Oxidation", "Reduction", "Corrosion", "Rancidity"],
        "key_formulas": [
            "Combination: A + B → AB",
            "Decomposition: AB → A + B",
            "Displacement: A + BC → AC + B",
            "Double Displacement: AB + CD → AD + CB",
        ],
        "quiz": [
            {"id":"q1","question":"What type of chemical reaction is: CaCO₃ → CaO + CO₂?","options":["Combination","Decomposition","Displacement","Double displacement"],"correctAnswerIndex":1,"explanation":"When one compound breaks into two or more substances, it is a decomposition reaction."},
            {"id":"q2","question":"In the reaction Zn + CuSO₄ → ZnSO₄ + Cu, what type of reaction is this?","options":["Combination","Decomposition","Displacement","Double displacement"],"correctAnswerIndex":2,"explanation":"Zinc displaces copper from copper sulphate solution because Zn is more reactive than Cu. This is a displacement (single) reaction."},
            {"id":"q3","question":"The process of gaining oxygen or losing hydrogen is called:","options":["Reduction","Oxidation","Neutralisation","Precipitation"],"correctAnswerIndex":1,"explanation":"Oxidation involves gain of oxygen OR loss of hydrogen. Reduction is the opposite."},
            {"id":"q4","question":"Which gas is evolved when dilute H₂SO₄ reacts with zinc?","options":["CO₂","SO₂","H₂","O₂"],"correctAnswerIndex":2,"explanation":"Zn + H₂SO₄ → ZnSO₄ + H₂↑. Hydrogen gas is produced when zinc reacts with dilute sulphuric acid."},
            {"id":"q5","question":"The deterioration of iron by oxidation in presence of water is called:","options":["Rancidity","Corrosion","Combustion","Decomposition"],"correctAnswerIndex":1,"explanation":"Corrosion is the deterioration of metals due to reaction with their environment. Rusting of iron is a common example."},
        ],
        "resources": [
            {"id":"v1","title":"Types of Chemical Reactions","type":"video","url":"https://www.youtube.com/watch?v=Nj8_lMrFMPg","thumbnailUrl":"https://img.youtube.com/vi/Nj8_lMrFMPg/hqdefault.jpg"},
            {"id":"a1","title":"Chemical Reactions – NCERT Chapter 1","type":"article","url":"https://ncert.nic.in/textbook/pdf/jesc101.pdf","thumbnailUrl":"https://via.placeholder.com/300x150/E74C3C/FFFFFF?text=Chemistry"},
        ],
    },
    "chem_10_02": {
        "title": "Acids, Bases and Salts",
        "subject": "Chemistry", "grade": 10,
        "concepts": ["Properties of Acids", "Properties of Bases", "pH Scale", "Neutralization", "Salts"],
        "key_formulas": [
            "pH scale: 0 (strong acid) to 14 (strong base), 7 = neutral",
            "Neutralization: Acid + Base → Salt + Water",
            "pH < 7: acidic | pH = 7: neutral | pH > 7: basic",
        ],
        "quiz": [
            {"id":"q1","question":"Litmus paper turns red in the presence of:","options":["Base","Acid","Salt","Neutral solution"],"correctAnswerIndex":1,"explanation":"Acids turn blue litmus paper red. Bases turn red litmus paper blue."},
            {"id":"q2","question":"The pH of a neutral solution at room temperature is:","options":["0","7","14","5"],"correctAnswerIndex":1,"explanation":"A perfectly neutral solution (like pure water at 25°C) has a pH of exactly 7."},
            {"id":"q3","question":"When sodium hydroxide reacts with hydrochloric acid, the products are:","options":["Na₂O + H₂","NaCl + H₂O","NaOH + Cl₂","Na + HCl"],"correctAnswerIndex":1,"explanation":"NaOH + HCl → NaCl + H₂O. This is a neutralisation reaction producing salt (NaCl) and water."},
            {"id":"q4","question":"Baking soda is chemically known as:","options":["Sodium chloride","Sodium carbonate","Sodium hydrogen carbonate","Calcium hydroxide"],"correctAnswerIndex":2,"explanation":"Baking soda is NaHCO₃ (sodium hydrogen carbonate or sodium bicarbonate)."},
            {"id":"q5","question":"A solution with pH = 3 is:","options":["Strongly basic","Weakly basic","Neutral","Acidic"],"correctAnswerIndex":3,"explanation":"pH < 7 is acidic. pH = 3 indicates an acidic solution (e.g., vinegar has pH ≈ 3)."},
        ],
        "resources": [
            {"id":"v1","title":"Acids, Bases and Salts – pH Scale","type":"video","url":"https://www.youtube.com/watch?v=0QLbjyHSA4I","thumbnailUrl":"https://img.youtube.com/vi/0QLbjyHSA4I/hqdefault.jpg"},
            {"id":"a1","title":"pH – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/PH","thumbnailUrl":"https://via.placeholder.com/300x150/27AE60/FFFFFF?text=pH+Scale"},
        ],
    },
    # ── Grade 10 Biology ──────────────────────────────────────────────────────
    "bio_10_01": {
        "title": "Life Processes",
        "subject": "Biology", "grade": 10,
        "concepts": ["Nutrition", "Respiration", "Transportation in Plants", "Transportation in Humans", "Excretion"],
        "key_formulas": [
            "Photosynthesis: 6CO₂ + 6H₂O + Light → C₆H₁₂O₆ + 6O₂",
            "Aerobic Respiration: C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + Energy (38 ATP)",
            "Anaerobic: Glucose → Ethanol + CO₂ + Energy (2 ATP)",
        ],
        "quiz": [
            {"id":"q1","question":"The process by which green plants prepare their own food is called:","options":["Respiration","Digestion","Photosynthesis","Transpiration"],"correctAnswerIndex":2,"explanation":"Photosynthesis is the process where plants use sunlight, CO₂, and water to produce glucose and oxygen."},
            {"id":"q2","question":"The site of photosynthesis in plants is the:","options":["Mitochondria","Chloroplast","Nucleus","Ribosome"],"correctAnswerIndex":1,"explanation":"Chloroplasts contain chlorophyll (the green pigment) and are the organelles where photosynthesis occurs."},
            {"id":"q3","question":"Which blood vessel carries oxygenated blood FROM the lungs TO the heart?","options":["Pulmonary artery","Aorta","Pulmonary vein","Vena cava"],"correctAnswerIndex":2,"explanation":"The pulmonary vein carries oxygenated blood from the lungs to the left atrium of the heart."},
            {"id":"q4","question":"The functional unit of the kidney is:","options":["Neuron","Nephron","Alveolus","Villus"],"correctAnswerIndex":1,"explanation":"The nephron is the structural and functional unit of the kidney. Each kidney has about one million nephrons."},
            {"id":"q5","question":"In aerobic respiration, the final products are:","options":["Ethanol and CO₂","CO₂ and H₂O","Lactic acid and CO₂","Glucose and O₂"],"correctAnswerIndex":1,"explanation":"Aerobic respiration: C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + Energy. Products are carbon dioxide and water."},
        ],
        "resources": [
            {"id":"v1","title":"Life Processes – Photosynthesis and Respiration","type":"video","url":"https://www.youtube.com/watch?v=3Q0mEChDgXM","thumbnailUrl":"https://img.youtube.com/vi/3Q0mEChDgXM/hqdefault.jpg"},
            {"id":"a1","title":"Photosynthesis – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Photosynthesis","thumbnailUrl":"https://via.placeholder.com/300x150/2ECC71/FFFFFF?text=Biology"},
        ],
    },
    "bio_10_02": {
        "title": "Control and Coordination",
        "subject": "Biology", "grade": 10,
        "concepts": ["Nervous System", "Neuron Structure", "Reflex Actions", "Hormones", "Plant Hormones"],
        "key_formulas": [
            "Reflex arc: Receptor → Sensory neuron → Spinal cord → Motor neuron → Effector",
        ],
        "quiz": [
            {"id":"q1","question":"The basic structural and functional unit of the nervous system is:","options":["Nerve fibre","Neuron","Brain","Spinal cord"],"correctAnswerIndex":1,"explanation":"A neuron (nerve cell) is the basic unit of the nervous system. It consists of a cell body, dendrites and an axon."},
            {"id":"q2","question":"Which hormone is secreted by the adrenal gland in response to stress?","options":["Insulin","Thyroxin","Adrenaline","Estrogen"],"correctAnswerIndex":2,"explanation":"Adrenaline (epinephrine) is secreted by the adrenal medulla and prepares the body for 'fight or flight' response."},
            {"id":"q3","question":"The reflex arc ensures:","options":["Voluntary actions","Quick involuntary responses","Thinking processes","Hormone secretion"],"correctAnswerIndex":1,"explanation":"Reflex arcs bypass the brain for quick, automatic responses to stimuli (e.g., pulling hand away from fire)."},
            {"id":"q4","question":"Which plant hormone promotes cell elongation and is responsible for phototropism?","options":["Cytokinin","Gibberellin","Auxin","Abscisic acid"],"correctAnswerIndex":2,"explanation":"Auxin causes unequal cell elongation in shoots, causing bending towards light (phototropism)."},
            {"id":"q5","question":"Insulin is secreted by which gland to regulate blood sugar?","options":["Thyroid","Adrenal","Pituitary","Pancreas"],"correctAnswerIndex":3,"explanation":"The Islets of Langerhans in the pancreas secrete insulin (and glucagon) to regulate blood glucose levels."},
        ],
        "resources": [
            {"id":"v1","title":"Human Nervous System Explained","type":"video","url":"https://www.youtube.com/watch?v=AhssFKqDXSk","thumbnailUrl":"https://img.youtube.com/vi/AhssFKqDXSk/hqdefault.jpg"},
            {"id":"a1","title":"Reflex Action – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Reflex","thumbnailUrl":"https://via.placeholder.com/300x150/8E44AD/FFFFFF?text=Nervous+System"},
        ],
    },
    # ── Grade 12 Physics ──────────────────────────────────────────────────────
    "phys_12_01": {
        "title": "Electric Charges and Fields",
        "subject": "Physics", "grade": 12,
        "concepts": ["Coulomb's Law", "Electric Field", "Electric Field Lines", "Gauss's Law", "Electric Flux"],
        "key_formulas": [
            "Coulomb's Law: F = k·q₁q₂/r² (k = 9×10⁹ N·m²/C²)",
            "Electric Field: E = F/q = kQ/r²",
            "Gauss's Law: ΦE = Q_enclosed / ε₀",
            "ε₀ = 8.854×10⁻¹² C²/(N·m²)",
        ],
        "quiz": [
            {"id":"q1","question":"Coulomb's law gives force between charges as inversely proportional to:","options":["Distance r","Square of distance r²","Cube of distance r³","√r"],"correctAnswerIndex":1,"explanation":"F = kq₁q₂/r². The force varies as the inverse square of the distance between the charges."},
            {"id":"q2","question":"The direction of electric field lines near a negative charge is:","options":["Away from the charge","Towards the charge","Circular around the charge","Parallel to the charge"],"correctAnswerIndex":1,"explanation":"Electric field lines point in the direction a positive test charge would move — towards negative charges."},
            {"id":"q3","question":"If the electric flux through a closed surface is zero, the total charge enclosed is:","options":["Infinite","Positive","Zero","Cannot determine"],"correctAnswerIndex":2,"explanation":"By Gauss's Law: ΦE = Q_enc/ε₀. If ΦE = 0, then Q_enc = 0 (net enclosed charge is zero)."},
            {"id":"q4","question":"Two charges of +2 μC and −2 μC separated by 0.1 m. The force between them is: (k=9×10⁹)","options":["3.6 N attractive","3.6 N repulsive","36 N attractive","0.36 N attractive"],"correctAnswerIndex":0,"explanation":"F = k×q₁×q₂/r² = 9×10⁹ × 2×10⁻⁶ × 2×10⁻⁶ / (0.1)² = 9×10⁹ × 4×10⁻¹² / 0.01 = 3.6 N. Opposite charges → attractive."},
            {"id":"q5","question":"Electric field inside a conducting sphere (conductor) with charge on its surface is:","options":["Maximum at centre","Zero","Equal to surface field","Proportional to radius"],"correctAnswerIndex":1,"explanation":"Inside a conductor in electrostatic equilibrium, the electric field is zero. All charges reside on the surface."},
        ],
        "resources": [
            {"id":"v1","title":"Electric Charges and Fields – Class 12 Physics","type":"video","url":"https://www.youtube.com/watch?v=ZkJkXO5wIwQ","thumbnailUrl":"https://img.youtube.com/vi/ZkJkXO5wIwQ/hqdefault.jpg"},
            {"id":"a1","title":"Coulomb's Law – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Coulomb%27s_law","thumbnailUrl":"https://via.placeholder.com/300x150/1ABC9C/FFFFFF?text=Electrostatics"},
        ],
    },
    "phys_12_02": {
        "title": "Electrostatic Potential and Capacitance",
        "subject": "Physics", "grade": 12,
        "concepts": ["Electric Potential", "Equipotential Surfaces", "Capacitors", "Dielectrics", "Energy Stored"],
        "key_formulas": [
            "Electric Potential: V = kQ/r",
            "Potential Difference: W = qV",
            "Capacitance: C = Q/V",
            "Energy stored: U = ½CV² = Q²/2C",
            "Capacitors in series: 1/C_eq = 1/C₁ + 1/C₂",
            "Capacitors in parallel: C_eq = C₁ + C₂",
        ],
        "quiz": [
            {"id":"q1","question":"The SI unit of electric potential is:","options":["Newton","Coulomb","Volt","Farad"],"correctAnswerIndex":2,"explanation":"Electric potential is measured in Volts (V). 1 Volt = 1 Joule/Coulomb."},
            {"id":"q2","question":"Work done in moving a charge along an equipotential surface is:","options":["Maximum","Minimum","Zero","Equal to qV"],"correctAnswerIndex":2,"explanation":"Along an equipotential surface, V is constant. Work W = q(V₁ − V₂) = 0."},
            {"id":"q3","question":"A capacitor of 4 μF is charged to 100 V. Energy stored is:","options":["0.02 J","0.04 J","0.2 J","400 J"],"correctAnswerIndex":0,"explanation":"U = ½CV² = ½ × 4×10⁻⁶ × 100² = ½ × 4×10⁻⁶ × 10000 = 0.02 J."},
            {"id":"q4","question":"Inserting a dielectric into a capacitor at constant voltage:","options":["Decreases capacitance","Increases capacitance","Has no effect","Discharges the capacitor"],"correctAnswerIndex":1,"explanation":"C = Kε₀A/d. Dielectric constant K > 1, so capacitance increases when a dielectric is inserted."},
            {"id":"q5","question":"Two capacitors 2 μF and 3 μF in series have equivalent capacitance:","options":["5 μF","1 μF","1.2 μF","6 μF"],"correctAnswerIndex":2,"explanation":"1/C = 1/2 + 1/3 = 5/6. So C = 6/5 = 1.2 μF."},
        ],
        "resources": [
            {"id":"v1","title":"Capacitors and Electric Potential","type":"video","url":"https://www.youtube.com/watch?v=ZkJkXO5wIwQ","thumbnailUrl":"https://img.youtube.com/vi/ZkJkXO5wIwQ/hqdefault.jpg"},
            {"id":"a1","title":"Capacitor – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Capacitor","thumbnailUrl":"https://via.placeholder.com/300x150/2980B9/FFFFFF?text=Capacitor"},
        ],
    },
    "phys_12_03": {
        "title": "Current Electricity",
        "subject": "Physics", "grade": 12,
        "concepts": ["Drift Velocity", "Ohm's Law", "Kirchhoff's Laws", "Wheatstone Bridge", "Potentiometer"],
        "key_formulas": [
            "Ohm's Law: V = IR",
            "Kirchhoff's Current Law (KCL): ΣI at junction = 0",
            "Kirchhoff's Voltage Law (KVL): ΣV in loop = 0",
            "Wheatstone Bridge: P/Q = R/S (balanced condition)",
            "Resistivity: R = ρL/A",
        ],
        "quiz": [
            {"id":"q1","question":"Kirchhoff's Current Law (KCL) is based on conservation of:","options":["Energy","Momentum","Charge","Mass"],"correctAnswerIndex":2,"explanation":"KCL states that the algebraic sum of currents at any junction is zero — based on conservation of electric charge."},
            {"id":"q2","question":"In a balanced Wheatstone bridge, P/Q = R/S. If P=2, Q=4, R=5, what is S?","options":["10","5","2.5","20"],"correctAnswerIndex":0,"explanation":"P/Q = R/S → S = QR/P = 4×5/2 = 10."},
            {"id":"q3","question":"The resistivity of a conductor depends on:","options":["Length and area","Temperature and material","Applied voltage","Current flowing"],"correctAnswerIndex":1,"explanation":"Resistivity (ρ) is an intrinsic property of the material and varies with temperature. It does not depend on size/shape."},
            {"id":"q4","question":"The EMF of a cell is measured using a potentiometer because:","options":["It is faster","No current flows through the cell at balance","It is cheaper","It gives approximate values"],"correctAnswerIndex":1,"explanation":"At the balance point of a potentiometer, no current flows through the cell being measured, giving the true EMF."},
            {"id":"q5","question":"Three resistors of 6Ω each are connected in a delta. The equivalent resistance between any two terminals is:","options":["2Ω","3Ω","4Ω","9Ω"],"correctAnswerIndex":2,"explanation":"For delta: two resistors in series (12Ω) parallel with one (6Ω): R = 12×6/(12+6) = 72/18 = 4Ω."},
        ],
        "resources": [
            {"id":"v1","title":"Kirchhoff's Laws Explained","type":"video","url":"https://www.youtube.com/watch?v=TTLAm6sfuWs","thumbnailUrl":"https://img.youtube.com/vi/TTLAm6sfuWs/hqdefault.jpg"},
            {"id":"a1","title":"Kirchhoff's Circuit Laws – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Kirchhoff%27s_circuit_laws","thumbnailUrl":"https://via.placeholder.com/300x150/E74C3C/FFFFFF?text=Circuits"},
        ],
    },
    # ── Grade 12 Mathematics ──────────────────────────────────────────────────
    "math_12_01": {
        "title": "Relations and Functions",
        "subject": "Mathematics", "grade": 12,
        "concepts": ["Types of Relations", "Types of Functions", "Composite Functions", "Inverse Functions", "Binary Operations"],
        "key_formulas": [
            "A function f: A → B is one-one (injective) if f(a₁) = f(a₂) ⟹ a₁ = a₂",
            "A function f: A → B is onto (surjective) if every b ∈ B has pre-image in A",
            "Bijective = one-one AND onto (invertible)",
            "Composite function: (gof)(x) = g(f(x))",
        ],
        "quiz": [
            {"id":"q1","question":"A relation R on set A is symmetric if:","options":["aRb ⟹ bRa","aRb and bRc ⟹ aRc","aRa for all a","None of these"],"correctAnswerIndex":0,"explanation":"A relation R is symmetric if for every (a,b) ∈ R, we also have (b,a) ∈ R."},
            {"id":"q2","question":"The function f(x) = x² from R to R is:","options":["One-one and onto","One-one but not onto","Onto but not one-one","Neither one-one nor onto"],"correctAnswerIndex":3,"explanation":"f(x) = x² is not one-one (f(2) = f(−2) = 4) and not onto (no x for f(x) = −1)."},
            {"id":"q3","question":"If f(x) = 2x + 1 and g(x) = x − 3, then fog(x) is:","options":["2x − 5","2x − 3","x − 1","2x + 5"],"correctAnswerIndex":0,"explanation":"fog(x) = f(g(x)) = f(x−3) = 2(x−3) + 1 = 2x − 6 + 1 = 2x − 5."},
            {"id":"q4","question":"A bijective function always has:","options":["No inverse","Partial inverse","A unique inverse function","Multiple inverses"],"correctAnswerIndex":2,"explanation":"A bijective (one-one + onto) function has a unique inverse function f⁻¹ such that f⁻¹(f(x)) = x."},
            {"id":"q5","question":"An equivalence relation must satisfy:","options":["Reflexive only","Reflexive and symmetric","Reflexive, symmetric, and transitive","Transitive only"],"correctAnswerIndex":2,"explanation":"An equivalence relation must be reflexive (aRa), symmetric (aRb ⟹ bRa), and transitive (aRb and bRc ⟹ aRc)."},
        ],
        "resources": [
            {"id":"v1","title":"Relations and Functions – Class 12 Maths","type":"video","url":"https://www.youtube.com/watch?v=RUOAMRlNeD4","thumbnailUrl":"https://img.youtube.com/vi/RUOAMRlNeD4/hqdefault.jpg"},
            {"id":"a1","title":"Function (mathematics) – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Function_(mathematics)","thumbnailUrl":"https://via.placeholder.com/300x150/9B59B6/FFFFFF?text=Functions"},
        ],
    },
    "math_12_02": {
        "title": "Calculus – Derivatives",
        "subject": "Mathematics", "grade": 12,
        "concepts": ["Limits", "Continuity", "Differentiation Rules", "Chain Rule", "Applications of Derivatives"],
        "key_formulas": [
            "d/dx(xⁿ) = nxⁿ⁻¹",
            "d/dx(sin x) = cos x; d/dx(cos x) = −sin x",
            "d/dx(eˣ) = eˣ; d/dx(ln x) = 1/x",
            "Chain Rule: d/dx[f(g(x))] = f′(g(x))·g′(x)",
            "Product Rule: d/dx[uv] = u′v + uv′",
        ],
        "quiz": [
            {"id":"q1","question":"The derivative of x⁵ with respect to x is:","options":["x⁴","5x⁴","5x⁵","4x⁴"],"correctAnswerIndex":1,"explanation":"By power rule: d/dx(xⁿ) = nxⁿ⁻¹. So d/dx(x⁵) = 5x⁴."},
            {"id":"q2","question":"If y = sin(3x), then dy/dx is:","options":["cos(3x)","3cos(3x)","-cos(3x)","3sin(3x)"],"correctAnswerIndex":1,"explanation":"Using chain rule: d/dx(sin(3x)) = cos(3x) × d/dx(3x) = 3cos(3x)."},
            {"id":"q3","question":"The function f(x) = |x| is not differentiable at:","options":["x = 1","x = −1","x = 0","x = ∞"],"correctAnswerIndex":2,"explanation":"f(x) = |x| has a sharp corner at x = 0. The left derivative (−1) ≠ right derivative (+1), so it's not differentiable at x = 0."},
            {"id":"q4","question":"At a maximum or minimum point, dy/dx equals:","options":["1","−1","0","∞"],"correctAnswerIndex":2,"explanation":"At local maxima or minima, the tangent to the curve is horizontal (slope = 0), so dy/dx = 0 (critical point condition)."},
            {"id":"q5","question":"d/dx(eˣ) equals:","options":["xeˣ⁻¹","eˣ","eˣ⁻¹","1/eˣ"],"correctAnswerIndex":1,"explanation":"The exponential function eˣ is its own derivative: d/dx(eˣ) = eˣ. This unique property makes it fundamental in calculus."},
        ],
        "resources": [
            {"id":"v1","title":"Introduction to Derivatives – 3Blue1Brown","type":"video","url":"https://www.youtube.com/watch?v=9vKqVkMQHKk","thumbnailUrl":"https://img.youtube.com/vi/9vKqVkMQHKk/hqdefault.jpg"},
            {"id":"a1","title":"Derivative – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Derivative","thumbnailUrl":"https://via.placeholder.com/300x150/E67E22/FFFFFF?text=Calculus"},
        ],
    },
    "math_12_03": {
        "title": "Integrals",
        "subject": "Mathematics", "grade": 12,
        "concepts": ["Indefinite Integrals", "Integration by Substitution", "Integration by Parts", "Definite Integrals", "Area Under Curve"],
        "key_formulas": [
            "∫xⁿ dx = xⁿ⁺¹/(n+1) + C (n ≠ −1)",
            "∫eˣ dx = eˣ + C",
            "∫sin x dx = −cos x + C",
            "Integration by Parts: ∫u dv = uv − ∫v du",
            "∫ₐᵇ f(x) dx = F(b) − F(a) (Fundamental Theorem of Calculus)",
        ],
        "quiz": [
            {"id":"q1","question":"∫x³ dx equals:","options":["3x²","x⁴","x⁴/4 + C","4x⁴"],"correctAnswerIndex":2,"explanation":"∫xⁿ dx = xⁿ⁺¹/(n+1) + C. So ∫x³ dx = x⁴/4 + C."},
            {"id":"q2","question":"The value of ∫₀¹ x² dx is:","options":["1/2","1/3","1/4","1"],"correctAnswerIndex":1,"explanation":"∫₀¹ x² dx = [x³/3]₀¹ = 1/3 − 0 = 1/3."},
            {"id":"q3","question":"∫cos x dx equals:","options":["sin x + C","−sin x + C","tan x + C","sec x + C"],"correctAnswerIndex":0,"explanation":"The antiderivative of cos x is sin x. Verify: d/dx(sin x) = cos x. So ∫cos x dx = sin x + C."},
            {"id":"q4","question":"Integration by substitution is useful when:","options":["Integrand is a product","Integrand is a composite function","Integrand has fractions","None of these"],"correctAnswerIndex":1,"explanation":"Substitution (u-substitution) simplifies composite functions by replacing the inner function with u."},
            {"id":"q5","question":"The Fundamental Theorem of Calculus connects:","options":["Differentiation and limits","Integration and differentiation","Algebra and geometry","Trigonometry and calculus"],"correctAnswerIndex":1,"explanation":"The Fundamental Theorem of Calculus states that differentiation and integration are inverse operations: ∫ₐᵇ f(x)dx = F(b)−F(a)."},
        ],
        "resources": [
            {"id":"v1","title":"Integration and the Fundamental Theorem","type":"video","url":"https://www.youtube.com/watch?v=rfG8ce4nNh0","thumbnailUrl":"https://img.youtube.com/vi/rfG8ce4nNh0/hqdefault.jpg"},
            {"id":"a1","title":"Integral – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Integral","thumbnailUrl":"https://via.placeholder.com/300x150/3498DB/FFFFFF?text=Integrals"},
        ],
    },
    # ── Grade 12 Computer Science ──────────────────────────────────────────────
    "cs_12_01": {
        "title": "Python Revision Tour",
        "subject": "Computer Science", "grade": 12,
        "concepts": ["Data Types", "Variables", "Operators", "Control Flow", "Functions", "Modules"],
        "key_formulas": [
            "int, float, str, bool, list, tuple, dict, set",
            "Arithmetic: +, -, *, /, //, %, **",
            "Comparison: ==, !=, <, >, <=, >=",
            "Logical: and, or, not",
        ],
        "quiz": [
            {"id":"q1","question":"What is the output of: print(type(3.14))?","options":["<class 'int'>","<class 'float'>","<class 'str'>","<class 'double'>"],"correctAnswerIndex":1,"explanation":"3.14 is a floating-point literal in Python, so type(3.14) returns <class 'float'>."},
            {"id":"q2","question":"What does // operator do in Python?","options":["Division with remainder","Integer (floor) division","Exponentiation","Modulo"],"correctAnswerIndex":1,"explanation":"// is the floor division operator. 7 // 2 = 3 (discards the decimal part)."},
            {"id":"q3","question":"Which of these is a mutable data type in Python?","options":["int","str","tuple","list"],"correctAnswerIndex":3,"explanation":"Lists are mutable (can be changed after creation). int, str, and tuple are immutable."},
            {"id":"q4","question":"The range() function range(2, 10, 3) generates:","options":["[2, 5, 8]","[2, 3, 5, 8]","[2, 4, 7, 10]","[2, 5, 9]"],"correctAnswerIndex":0,"explanation":"range(start, stop, step): starts at 2, increments by 3, stops before 10. Values: 2, 5, 8."},
            {"id":"q5","question":"To import only the sqrt function from the math module, use:","options":["import math.sqrt","from math import sqrt","include math, sqrt","using math.sqrt"],"correctAnswerIndex":1,"explanation":"'from math import sqrt' imports only sqrt. You can then use sqrt() directly without the math. prefix."},
        ],
        "resources": [
            {"id":"v1","title":"Python Tutorial for Beginners","type":"video","url":"https://www.youtube.com/watch?v=_uQrJ0TkZlc","thumbnailUrl":"https://img.youtube.com/vi/_uQrJ0TkZlc/hqdefault.jpg"},
            {"id":"a1","title":"Python Programming Language – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Python_(programming_language)","thumbnailUrl":"https://via.placeholder.com/300x150/3572A5/FFFFFF?text=Python"},
            {"id":"a2","title":"Python Docs – Built-in Functions","type":"article","url":"https://docs.python.org/3/library/functions.html","thumbnailUrl":"https://via.placeholder.com/300x150/F1C40F/333333?text=Python+Docs"},
        ],
    },
    "cs_12_02": {
        "title": "Data Structures in Python",
        "subject": "Computer Science", "grade": 12,
        "concepts": ["Stacks", "Queues", "Linked Lists", "Searching Algorithms", "Sorting Algorithms"],
        "key_formulas": [
            "Stack: LIFO (Last In, First Out) — push(), pop()",
            "Queue: FIFO (First In, First Out) — enqueue(), dequeue()",
            "Binary Search: O(log n) | Linear Search: O(n)",
            "Bubble Sort: O(n²) | Quick Sort: O(n log n) average",
        ],
        "quiz": [
            {"id":"q1","question":"A stack follows which principle?","options":["FIFO","LIFO","Random access","LILO"],"correctAnswerIndex":1,"explanation":"Stack follows LIFO — Last In, First Out. The last element pushed is the first one popped."},
            {"id":"q2","question":"Which searching algorithm requires the list to be sorted first?","options":["Linear Search","Sequential Search","Binary Search","Hashing"],"correctAnswerIndex":2,"explanation":"Binary Search requires a sorted list. It repeatedly divides the search interval in half, achieving O(log n) complexity."},
            {"id":"q3","question":"The time complexity of Bubble Sort in the worst case is:","options":["O(n)","O(n log n)","O(n²)","O(log n)"],"correctAnswerIndex":2,"explanation":"Bubble Sort uses nested loops: outer loop n times, inner loop n times → O(n²) worst and average case."},
            {"id":"q4","question":"In Python, a stack can be implemented using a:","options":["Dictionary","Set","List with append() and pop()","Tuple"],"correctAnswerIndex":2,"explanation":"Python list's append() acts as push and pop() (default removes last) acts as pop — LIFO behaviour."},
            {"id":"q5","question":"A queue in Python can be efficiently implemented using:","options":["list (append/pop)","collections.deque","tuple","set"],"correctAnswerIndex":1,"explanation":"collections.deque provides O(1) append (right) and popleft() for FIFO queue operations."},
        ],
        "resources": [
            {"id":"v1","title":"Data Structures in Python","type":"video","url":"https://www.youtube.com/watch?v=pkYVOmU3MgA","thumbnailUrl":"https://img.youtube.com/vi/pkYVOmU3MgA/hqdefault.jpg"},
            {"id":"a1","title":"Data Structure – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Data_structure","thumbnailUrl":"https://via.placeholder.com/300x150/E74C3C/FFFFFF?text=Data+Structures"},
        ],
    },
    # ── Grade 12 Chemistry ────────────────────────────────────────────────────
    "chem_12_01": {
        "title": "Electrochemistry",
        "subject": "Chemistry", "grade": 12,
        "concepts": ["Galvanic Cells", "Standard Electrode Potential", "Nernst Equation", "Electrolysis", "Faraday's Laws"],
        "key_formulas": [
            "Cell EMF: E°cell = E°cathode − E°anode",
            "Nernst Equation: E = E° − (RT/nF)·ln Q",
            "At 298K: E = E° − (0.0592/n)·log Q",
            "Faraday's First Law: m = (M × I × t) / (n × F)",
            "F = 96500 C/mol (Faraday constant)",
        ],
        "quiz": [
            {"id":"q1","question":"In a galvanic cell, oxidation occurs at the:","options":["Cathode","Anode","Salt bridge","Electrolyte"],"correctAnswerIndex":1,"explanation":"In galvanic (voltaic) cells, oxidation (loss of electrons) occurs at the anode (negative electrode)."},
            {"id":"q2","question":"The standard hydrogen electrode (SHE) has electrode potential:","options":["1.0 V","0.5 V","0 V","−1.0 V"],"correctAnswerIndex":2,"explanation":"By convention, the standard hydrogen electrode (SHE) is assigned a potential of exactly 0.00 V."},
            {"id":"q3","question":"The purpose of the salt bridge in a galvanic cell is to:","options":["Increase current","Complete the circuit and maintain electrical neutrality","Generate EMF","Store charge"],"correctAnswerIndex":1,"explanation":"The salt bridge allows flow of ions between the two half-cells, maintaining electrical neutrality without mixing solutions."},
            {"id":"q4","question":"According to Faraday's First Law, mass deposited during electrolysis is proportional to:","options":["Voltage applied","Quantity of charge (Q = It)","Concentration of solution","Temperature"],"correctAnswerIndex":1,"explanation":"Faraday's First Law: m ∝ Q. Mass deposited is directly proportional to the quantity of electric charge passed."},
            {"id":"q5","question":"For the cell Cu²⁺/Cu (E° = +0.34V) vs Zn²⁺/Zn (E° = −0.76V), E°cell is:","options":["−1.10 V","1.10 V","0.42 V","−0.42 V"],"correctAnswerIndex":1,"explanation":"E°cell = E°cathode − E°anode = 0.34 − (−0.76) = 1.10 V. Cu is cathode (reduced), Zn is anode (oxidised)."},
        ],
        "resources": [
            {"id":"v1","title":"Electrochemistry – Galvanic Cells","type":"video","url":"https://www.youtube.com/watch?v=YFlqXkiRJqY","thumbnailUrl":"https://img.youtube.com/vi/YFlqXkiRJqY/hqdefault.jpg"},
            {"id":"a1","title":"Electrochemistry – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Electrochemistry","thumbnailUrl":"https://via.placeholder.com/300x150/16A085/FFFFFF?text=Electrochemistry"},
        ],
    },
    "chem_12_02": {
        "title": "Chemical Kinetics",
        "subject": "Chemistry", "grade": 12,
        "concepts": ["Rate of Reaction", "Rate Laws", "Order of Reaction", "Arrhenius Equation", "Collision Theory"],
        "key_formulas": [
            "Rate = k[A]ᵐ[B]ⁿ (rate law)",
            "Arrhenius Equation: k = Ae^(−Ea/RT)",
            "Half-life (1st order): t₁/₂ = 0.693/k",
            "Activation Energy: Ea",
        ],
        "quiz": [
            {"id":"q1","question":"The rate of a chemical reaction increases with increasing temperature because:","options":["Activation energy increases","More molecules have energy ≥ Ea","Concentration increases","Pressure increases"],"correctAnswerIndex":1,"explanation":"Higher temperature increases kinetic energy of molecules, so more molecules exceed the activation energy threshold, increasing reaction rate."},
            {"id":"q2","question":"For a first-order reaction, the half-life is:","options":["Independent of initial concentration","Dependent on initial concentration","Equal to rate constant","Zero"],"correctAnswerIndex":0,"explanation":"For first-order: t₁/₂ = 0.693/k. This is independent of initial concentration, unlike zero or second-order reactions."},
            {"id":"q3","question":"If rate = k[A]²[B], the overall order of reaction is:","options":["1","2","3","0"],"correctAnswerIndex":2,"explanation":"Overall order = sum of powers in rate law = 2 (for [A]²) + 1 (for [B]) = 3 (third order overall)."},
            {"id":"q4","question":"A catalyst increases reaction rate by:","options":["Increasing temperature","Increasing reactant concentration","Lowering activation energy","Changing equilibrium position"],"correctAnswerIndex":2,"explanation":"A catalyst provides an alternative reaction pathway with lower activation energy, increasing reaction rate without being consumed."},
            {"id":"q5","question":"The Arrhenius equation shows that rate constant k:","options":["Increases exponentially with temperature","Decreases with temperature","Is independent of temperature","Depends only on concentration"],"correctAnswerIndex":0,"explanation":"k = Ae^(−Ea/RT). As T increases, −Ea/RT becomes less negative, e^(−Ea/RT) increases, so k increases exponentially."},
        ],
        "resources": [
            {"id":"v1","title":"Chemical Kinetics – Rate Laws","type":"video","url":"https://www.youtube.com/watch?v=SFuKiVr8M4I","thumbnailUrl":"https://img.youtube.com/vi/SFuKiVr8M4I/hqdefault.jpg"},
            {"id":"a1","title":"Chemical Kinetics – Wikipedia","type":"article","url":"https://en.wikipedia.org/wiki/Chemical_kinetics","thumbnailUrl":"https://via.placeholder.com/300x150/C0392B/FFFFFF?text=Kinetics"},
        ],
    },
}

# ─── MCP Server Setup ─────────────────────────────────────────────────────────

server = Server("edu-mcp-server")

# ─── Resources ───────────────────────────────────────────────────────────────

@server.list_resources()
async def handle_list_resources() -> list[types.Resource]:
    return [
        types.Resource(
            uri="student://profile",
            name="Student Learning Profile",
            description="Schema for the student profile including grade, learning style, interests, and performance history.",
            mimeType="application/json",
        ),
        types.Resource(
            uri="curriculum://chapters",
            name="Full Curriculum Chapter Catalogue",
            description="All chapters across Grade 10 and Grade 12 with titles, concepts, and estimated times.",
            mimeType="application/json",
        ),
        types.Resource(
            uri="xapi://statements",
            name="xAPI Learning Statements Log",
            description="xAPI-compatible learning event statements recorded during student sessions.",
            mimeType="application/json",
        ),
    ]


@server.read_resource()
async def handle_read_resource(uri: types.AnyUrl) -> str:
    uri_str = str(uri)

    if uri_str == "student://profile":
        schema = {
            "description": "Student profile resource. Passed dynamically as prompt arguments.",
            "schema": {
                "grade": "int (10 or 12)",
                "learningStyle": "visual | auditory | kinesthetic | readWrite",
                "interests": "List[str] — e.g. Technology, Sports, Music",
                "quizScores": "Map[chapterId, score(0-100)]",
                "consentGiven": "bool — FERPA/privacy consent status",
            },
            "privacyNote": "All student data is stored locally on-device. No data is transmitted externally.",
        }
        return json.dumps(schema, indent=2)

    if uri_str == "curriculum://chapters":
        summary = {
            chapter_id: {
                "title": data["title"],
                "subject": data["subject"],
                "grade": data["grade"],
                "concepts": data["concepts"],
            }
            for chapter_id, data in CHAPTER_DB.items()
        }
        return json.dumps(summary, indent=2)

    if uri_str == "xapi://statements":
        log_path = Path(__file__).parent / "xapi_statements.json"
        if log_path.exists():
            return log_path.read_text(encoding="utf-8")
        return json.dumps([])

    raise ValueError(f"Unknown resource URI: {uri_str}")


# ─── Prompts ──────────────────────────────────────────────────────────────────

@server.list_prompts()
async def handle_list_prompts() -> list[types.Prompt]:
    return [
        types.Prompt(
            name="synthesis_report",
            description="Generate a personalised markdown study synthesis report for a chapter, tailored to the student's learning style, interests, and difficulty level.",
            arguments=[
                types.PromptArgument(name="chapter_id", description="Chapter identifier (e.g. phys_10_01)", required=True),
                types.PromptArgument(name="grade", description="Student grade: 10 or 12", required=True),
                types.PromptArgument(name="learning_style", description="visual | auditory | kinesthetic | readWrite", required=True),
                types.PromptArgument(name="interests", description="Comma-separated interests e.g. Technology,Sports", required=False),
                types.PromptArgument(name="difficulty", description="basic | standard | advanced", required=False),
                types.PromptArgument(name="previous_score", description="Previous quiz score (0–100) for adaptive context", required=False),
            ],
        ),
        types.Prompt(
            name="generate_quiz",
            description="Generate an adaptive JSON quiz for a chapter, calibrated to the student's performance history and learning style.",
            arguments=[
                types.PromptArgument(name="chapter_id", description="Chapter identifier", required=True),
                types.PromptArgument(name="grade", description="Student grade: 10 or 12", required=True),
                types.PromptArgument(name="learning_style", description="Student learning style", required=True),
                types.PromptArgument(name="difficulty", description="basic | standard | advanced", required=False),
                types.PromptArgument(name="previous_score", description="Previous quiz score for adaptive difficulty", required=False),
            ],
        ),
    ]


@server.get_prompt()
async def handle_get_prompt(
    name: str, arguments: dict[str, str] | None
) -> types.GetPromptResult:
    args = arguments or {}

    if name == "synthesis_report":
        content = await _build_synthesis(args)
        return types.GetPromptResult(
            description=f"Personalised synthesis for {args.get('chapter_id', 'chapter')}",
            messages=[
                types.PromptMessage(
                    role="user",
                    content=types.TextContent(type="text", text=content),
                )
            ],
        )

    if name == "generate_quiz":
        content = await _build_quiz(args)
        return types.GetPromptResult(
            description=f"Adaptive quiz for {args.get('chapter_id', 'chapter')}",
            messages=[
                types.PromptMessage(
                    role="user",
                    content=types.TextContent(type="text", text=content),
                )
            ],
        )

    raise ValueError(f"Unknown prompt: {name}")


# ─── Tools ────────────────────────────────────────────────────────────────────

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="fetch_resources",
            description="Fetch curated multimedia learning resources (videos, articles) for a given chapter.",
            inputSchema={
                "type": "object",
                "properties": {
                    "chapter_id": {"type": "string", "description": "Chapter identifier"},
                    "learning_style": {"type": "string", "description": "Preferred learning style for resource filtering"},
                },
                "required": ["chapter_id"],
            },
        ),
        types.Tool(
            name="record_performance",
            description="Record a student's quiz performance as an xAPI-compatible learning statement.",
            inputSchema={
                "type": "object",
                "properties": {
                    "chapter_id": {"type": "string"},
                    "score": {"type": "number", "description": "Score 0–100"},
                    "completed": {"type": "boolean"},
                    "time_spent_seconds": {"type": "number"},
                },
                "required": ["chapter_id", "score"],
            },
        ),
        types.Tool(
            name="get_recommendations",
            description="Get next-chapter recommendations based on student performance history and learning context.",
            inputSchema={
                "type": "object",
                "properties": {
                    "grade": {"type": "number"},
                    "completed_chapters": {"type": "array", "items": {"type": "string"}},
                    "quiz_scores": {"type": "object", "description": "Map of chapterId to score"},
                },
                "required": ["grade"],
            },
        ),
    ]


@server.call_tool()
async def handle_call_tool(
    name: str, arguments: dict | None
) -> list[types.TextContent]:
    args = arguments or {}

    if name == "fetch_resources":
        result = _fetch_resources(args.get("chapter_id", ""), args.get("learning_style", ""))
        return [types.TextContent(type="text", text=json.dumps(result))]

    if name == "record_performance":
        result = _record_performance(args)
        return [types.TextContent(type="text", text=json.dumps(result))]

    if name == "get_recommendations":
        result = _get_recommendations(args)
        return [types.TextContent(type="text", text=json.dumps(result))]

    raise ValueError(f"Unknown tool: {name}")


# ─── Content Generation Helpers ──────────────────────────────────────────────

async def _build_synthesis(args: dict) -> str:
    chapter_id = args.get("chapter_id", "")
    grade = args.get("grade", "10")
    learning_style = args.get("learning_style", "visual")
    interests = args.get("interests", "")
    difficulty = args.get("difficulty", "standard")
    previous_score = args.get("previous_score", "")

    chapter = CHAPTER_DB.get(chapter_id, {})
    title = chapter.get("title", chapter_id.replace("_", " ").title())
    subject = chapter.get("subject", "")
    concepts = chapter.get("concepts", [])
    formulas = chapter.get("key_formulas", [])

    style_map = {
        "visual":      "Use visual descriptions, bullet-point hierarchies, ASCII diagrams, and spatial metaphors.",
        "auditory":    "Use a conversational narrative tone, storytelling analogies, and rhythmic phrasing.",
        "kinesthetic": "Focus on step-by-step procedures, hands-on experiments, and real-world problem solving.",
        "readWrite":   "Use formal academic prose with clear headings, detailed definitions, and structured notes.",
    }
    interest_ctx = f"Connect examples to the student's interests: {interests}." if interests else ""
    score_ctx = f"The student previously scored {previous_score}/100 — adjust explanation depth accordingly." if previous_score else ""

    prompt_text = f"""Generate a personalised Grade {grade} {subject} study report for:
**Chapter**: {title}
**Key Concepts**: {', '.join(concepts)}
**Learning Style**: {learning_style} — {style_map.get(learning_style, '')}
**Difficulty**: {difficulty}
{interest_ctx}
{score_ctx}

Structure the report with these markdown sections:
1. ## Overview
2. ## Key Concepts (with {learning_style}-tailored explanations)
3. ## Core Formulas & Principles
4. ## Worked Examples ({difficulty} level)
5. ## Memory Aids (optimised for {learning_style} learners)
6. ## Real-World Applications
7. ## Summary & Exam Tips
"""

    result = await _call_ai(prompt_text, max_tokens=2048)
    if result:
        return result

    # ── Fallback rich content ────────────────────────────────────────────────
    return _fallback_synthesis(title, subject, grade, concepts, formulas, learning_style, interests, difficulty, previous_score)


def _fallback_synthesis(title, subject, grade, concepts, formulas, learning_style, interests, difficulty, previous_score) -> str:
    style_intro = {
        "visual": f"> 🔭 **Visual Learner Mode** — Visualise each concept as a diagram. Use the concept map on the right to build connections.\n",
        "auditory": f"> 🎧 **Auditory Learner Mode** — Read aloud, discuss with peers, and listen to the linked video resources.\n",
        "kinesthetic": f"> ✋ **Kinesthetic Learner Mode** — Work through every example hands-on. Pause and solve before reading the solution.\n",
        "readWrite": f"> 📝 **Read/Write Learner Mode** — Take structured notes as you read. Rewrite key definitions in your own words.\n",
    }.get(learning_style, "")

    score_note = ""
    if previous_score:
        s = int(previous_score) if previous_score.isdigit() else 50
        if s < 50:
            score_note = "\n> ⚠️ **Focus Area**: Your previous score indicates some gaps. Pay extra attention to the fundamentals below.\n"
        elif s >= 80:
            score_note = "\n> 🌟 **Advanced Mode**: Your strong previous score unlocks deeper analysis sections below.\n"

    interest_list = [i.strip() for i in interests.split(",") if i.strip()] if interests else []

    report = f"# {title}\n"
    report += f"**Grade {grade} · {subject} · Difficulty: {difficulty.title()}**\n\n---\n\n"
    report += style_intro + score_note + "\n"
    report += "## Key Concepts\n\n"
    for concept in concepts:
        report += f"### {concept}\n"
        if learning_style == "visual":
            report += f"*Visualise*: Draw a diagram linking **{concept}** to related ideas.\n\n"
        elif learning_style == "auditory":
            report += f"*Say it*: Explain **{concept}** out loud to someone as if teaching them.\n\n"
        elif learning_style == "kinesthetic":
            report += f"*Do it*: Find a hands-on activity or experiment that demonstrates **{concept}**.\n\n"
        else:
            report += f"*Write it*: Write a full definition of **{concept}** in your notebook.\n\n"

    if formulas:
        report += "## Core Formulas & Principles\n\n"
        for formula in formulas:
            report += f"```\n{formula}\n```\n\n"

    if interest_list:
        report += "## Real-World Connections\n\n"
        for interest in interest_list[:3]:
            report += f"- **{interest}**: Concepts from this chapter appear in {interest.lower()} contexts and applications.\n"
        report += "\n"

    if difficulty == "advanced":
        report += "## Advanced Analysis\n\nFor deeper mastery, explore the derivations of the key formulas, consider edge cases, and solve higher-order application problems.\n\n"
    elif difficulty == "basic":
        report += "## Quick Review\n\nFocus on understanding the definitions and applying the most basic formula for each concept.\n\n"
    else:
        report += "## Summary & Exam Tips\n\n"
        report += "- **Recall** the key formulas — write them from memory daily.\n"
        report += "- **Apply** each concept to at least one numerical problem.\n"
        report += "- **Connect** concepts — they often appear together in exam questions.\n\n"

    report += "---\n*Generated by MCP StudyHub Educational Server · AI-Assisted Content*\n"
    return report


async def _build_quiz(args: dict) -> str:
    chapter_id = args.get("chapter_id", "")
    grade = args.get("grade", "10")
    learning_style = args.get("learning_style", "visual")
    difficulty = args.get("difficulty", "standard")
    previous_score = args.get("previous_score", "")

    chapter = CHAPTER_DB.get(chapter_id, {})
    title = chapter.get("title", chapter_id)
    concepts = chapter.get("concepts", [])

    # For teacher-added chapters not in CHAPTER_DB, generate via AI
    if chapter_id not in CHAPTER_DB:
        prompt_text = f"""Generate exactly 5 multiple-choice questions for Grade {grade} {title}.
Concepts covered: {', '.join(concepts)}
Difficulty: {difficulty}
Return ONLY a valid JSON array (no markdown, no explanation). Each object must have:
  id (string), question (string), options (array of 4 strings), correctAnswerIndex (int 0-3), explanation (string)"""
        raw = await _call_ai(prompt_text, max_tokens=1500)
        if raw:
            raw = raw.strip()
            if raw.startswith("```"):
                raw = raw.split("```")[1]
                if raw.startswith("json"):
                    raw = raw[4:]
            try:
                return json.dumps(json.loads(raw))
            except Exception:
                pass

    # Return pre-written questions from DB (or generic fallback)
    questions = chapter.get("quiz", _generic_quiz(title, concepts))
    return json.dumps(questions)


def _generic_quiz(title: str, concepts: list) -> list:
    return [
        {"id": "q1", "question": f"Which of the following best describes the study of {title}?",
         "options": [f"Analysis of {concepts[0] if concepts else 'core concepts'}", "Study of history", "Chemical analysis", "Statistical modelling"],
         "correctAnswerIndex": 0, "explanation": f"{title} primarily involves the analysis and application of {concepts[0] if concepts else 'core concepts'}."},
        {"id": "q2", "question": f"Which concept from {title} is most fundamental?",
         "options": [concepts[0] if len(concepts) > 0 else "Concept A", concepts[1] if len(concepts) > 1 else "Concept B", "Advanced theory", "Historical context"],
         "correctAnswerIndex": 0, "explanation": f"{concepts[0] if concepts else 'The first concept'} is typically the foundational principle."},
    ]


def _fetch_resources(chapter_id: str, learning_style: str) -> list:
    chapter = CHAPTER_DB.get(chapter_id, {})
    resources = chapter.get("resources", [])
    if not resources:
        resources = [
            {"id": "v1", "title": f"Introduction to {chapter.get('title', chapter_id)}", "type": "video",
             "url": "https://www.youtube.com/results?search_query=" + chapter.get('title', chapter_id).replace(" ", "+"),
             "thumbnailUrl": "https://via.placeholder.com/300x150/6C5CE7/FFFFFF?text=Video"},
            {"id": "a1", "title": f"{chapter.get('title', chapter_id)} – Wikipedia", "type": "article",
             "url": "https://en.wikipedia.org/wiki/Special:Search?search=" + chapter.get('title', chapter_id).replace(" ", "+"),
             "thumbnailUrl": "https://via.placeholder.com/300x150/00B894/FFFFFF?text=Article"},
        ]
    return resources


def _record_performance(args: dict) -> dict:
    statement = {
        "id": str(uuid.uuid4()),
        "actor": {"name": "Student", "mbox": "mailto:student@mcpstudyhub.local"},
        "verb": {
            "id": "http://adlnet.gov/expapi/verbs/scored",
            "display": {"en-US": "scored"},
        },
        "object": {
            "id": f"chapter://{args.get('chapter_id', 'unknown')}",
            "definition": {
                "name": {"en-US": CHAPTER_DB.get(args.get("chapter_id", ""), {}).get("title", args.get("chapter_id", ""))},
                "type": "http://adlnet.gov/expapi/activities/assessment",
            },
        },
        "result": {
            "score": {"scaled": args.get("score", 0) / 100, "raw": args.get("score", 0), "min": 0, "max": 100},
            "success": args.get("score", 0) >= 60,
            "completion": args.get("completed", False),
            "duration": f"PT{args.get('time_spent_seconds', 0)}S",
        },
        "context": {
            "platform": "MCP StudyHub",
            "language": "en-IN",
            "extensions": {"http://mcpstudyhub.local/extensions/protocol": "MCP/1.0"},
        },
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "stored": datetime.datetime.utcnow().isoformat() + "Z",
        "authority": {"name": "MCP StudyHub LRS", "mbox": "mailto:lrs@mcpstudyhub.local"},
        "version": "1.0.3",
    }
    log_path = Path(__file__).parent / "xapi_statements.json"
    existing = []
    if log_path.exists():
        try:
            existing = json.loads(log_path.read_text(encoding="utf-8"))
        except Exception:
            existing = []
    existing.append(statement)
    log_path.write_text(json.dumps(existing, indent=2), encoding="utf-8")
    return {"status": "recorded", "statement_id": statement["id"]}


def _get_recommendations(args: dict) -> list:
    grade = int(args.get("grade", 10))
    completed = set(args.get("completed_chapters", []))
    scores = args.get("quiz_scores", {})

    grade_chapters = [cid for cid, data in CHAPTER_DB.items() if data.get("grade") == grade]

    recommendations = []
    for cid in grade_chapters:
        if cid in completed:
            continue
        score = scores.get(cid, None)
        priority = "next"
        reason = "Continue your learning journey"
        if score is not None and score < 60:
            priority = "review"
            reason = f"You scored {score}% — revisiting this will strengthen your foundation"
        recommendations.append({
            "chapter_id": cid,
            "title": CHAPTER_DB[cid]["title"],
            "subject": CHAPTER_DB[cid]["subject"],
            "priority": priority,
            "reason": reason,
        })

    recommendations.sort(key=lambda x: 0 if x["priority"] == "review" else 1)
    return recommendations[:5]


# ─── Entry Point ──────────────────────────────────────────────────────────────

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="edu-mcp-server",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )


if __name__ == "__main__":
    asyncio.run(main())
