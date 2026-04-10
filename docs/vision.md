Vision: **"I want to gain a clear overview of what I spent my money on and how much I spent."**

---

## 1. Tracking: Fast & Intelligent
The goal is minimal effort when logging expenses to remove any daily friction.

* **Thumb-Friendly Entry:** The home screen keeps the recent transaction preview scrollable at the top while the entry form stays anchored below for one-handed input.
* **Instant Entry on Launch:** As soon as I open the app, the date field is active. I don't need to navigate; I can start selecting a date immediately.
* **Smart Suggestions (Autocomplete):** When I start typing a description (e.g., "Grocery Store"), the app recognizes my previous entries and automatically suggests the last amount and the matching category. One tap is enough to save.
* **Categorization:** I assign every expense to a category (e.g., Groceries, Household, Leisure) to understand the structure of my spending later on.
* **Two-Step Category Choice:** I open one consistent modal picker, choose the parent category first, and then immediately see only the matching subcategories. This reduces mistakes and keeps create/edit flows consistent.
* **Category Management:** I can see at a glance how many transactions belong to each category, and category hierarchies are always expanded for easy navigation.
* **In-Screen Guidance:** Every main tab offers a help action that explains what I can do in that view.

## 2. Automation: Managing Fixed Costs
Recurring expenses shouldn't require manual work every month.

* **Recurring Expenses:** I can set up subscriptions, rent, or insurance as recurring items. The app automatically logs these amounts at the chosen interval (monthly, yearly).
* **Next Transaction Preview:** While creating or editing a recurring rule, I can see the calculated next transaction date immediately to verify the schedule is correct. Inactive rules show the date greyed out.
* **Instant Generation:** If I want to log a recurring expense immediately instead of waiting for the automated date, I can click "Generate Now" directly from the edit form.
* **Completeness Without Typing:** Because of these automatic entries, I can see at the beginning of the month how much money is "already gone" due to my fixed costs.

## 3. Analysis: Understanding Instead of Just Collecting
This is where data turns into insights.

* **Time-Based Overview:** I can toggle between a monthly and a yearly view to identify trends in my spending behavior.
* **Visual Analysis:** A chart shows me at a glance the percentage share of my categories relative to my total spending. I can immediately see if I spent "too much" on leisure this month.
* **Interactive Drill-down:** If a category in the pie chart catches my eye, or if I tap a period in the bar chart, I can jump directly to a filtered transaction list.
* **Transaction Count:** In the transactions overview, I see the number of transactions in parentheses next to the total (e.g., "Gesamt: €150.50 (5)") so I know how many expenses make up that sum.
* **Readable History:** The transaction list shows month separators and a filtered total so month changes are visible instantly. Each transaction displays the category path (Category → Subcategory) for clarity.

## 4. Data: Privacy & Flexibility
Privacy without sacrificing convenience.

* **Local Control:** My financial data belongs to me. It is stored securely on my smartphone without any third party reading along.
* **Export Option:** I can export my data as a file at any time to back it up manually or to synchronize it with my own cloud (e.g., Nextcloud) later on.
* **Multiple Import Formats:** I can import data from different sources:
  - **Monekin CSV:** Standard format with parent/child categories and custom descriptions.
  - **DKB Bank CSV:** German bank export format. The app automatically looks up categories by recipient name from my transaction history, and if there is no match it falls back to a shared `Import` category.
* **Import Safety Rules:** During CSV import, positive values (credits) are skipped, category colors are assigned deterministically, fallback categories are created only when needed, and subcategories inherit their parent color.
* **Biometric Protection:** I can protect app access via fingerprint/face so that my spending remains private, even if I hand my phone to someone else.
* **Acknowledgments:** Links to [GitHub](https://github.com/karoc123/SpendingLog/blob/main/LICENSE) (GPL-3.0) and [Monekin](https://github.com/enrique-lozano/Monekin) are available in settings for transparency.

---

### The Vision in Daily Life:
You open the app at the checkout, type **"12.50"**, write **"Lunch"**, the app recognizes **"Category: Food"**, and you hit save. Done. 

In the evening, you click on the **"Food"** section in your statistics and see: *"Ah, I've eaten out 5 times this month – that's a total of €62.50."* – **Full control, zero stress.**


---

### The Vision in Daily Life:
You open the app at the checkout, type **"12.50"**, write **"Lunch"**, the app recognizes **"Category: Food"**, and you hit save. Done. 

In the evening, you click on the **"Food"** section in your statistics and see: *"Ah, I've eaten out 5 times this month – that's a total of €62.50."* – **Full control, zero stress.**
