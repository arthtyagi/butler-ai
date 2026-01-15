# Zepto Core Operations

## Check Login Status

```javascript
async function isLoggedIn(page) {
  // Method 1: Check for personalized address
  const hasAddress = await page
    .locator('button:has-text("home"), button:has-text("work")')
    .count();
  if (hasAddress > 0) return true;

  // Method 2: Check for "Select Location" (not logged in or no address)
  const selectLocation = await page
    .locator('button:has-text("Select Location")')
    .count();

  // Method 3: Check profile area
  const profileText = await page
    .locator('[data-testid="my-account"]')
    .textContent()
    .catch(() => "");

  return !selectLocation || profileText !== "profile";
}
```

## Select Address

```javascript
async function selectAddress(page, addressType = "home") {
  // Step 1: Open location modal
  const locationBtn = page
    .locator('button:has-text("Select Location"), [data-testid="user-address"]')
    .first();
  await locationBtn.click();
  await page.waitForTimeout(1500);

  // Step 2: Wait for modal
  await page
    .waitForSelector(
      '[data-testid="address-modal"], [data-testid="saved-address-list"]',
      { timeout: 5000 }
    )
    .catch(() => console.log("Modal selector not found, trying alternative"));

  // Step 3: Find and click address
  const addressSelectors = [
    `[data-testid="address-item"]:has-text("${addressType}")`,
    `[data-testid="address-item"]:first-child`,
    `div:has-text("${addressType}"):has(i[role="presentation"])`,
  ];

  for (const selector of addressSelectors) {
    const el = page.locator(selector).first();
    if ((await el.count()) > 0) {
      await el.click();
      await page.waitForTimeout(2000);
      return true;
    }
  }

  return false;
}
```

## Search Products

```javascript
async function searchProducts(page, query, limit = 5) {
  // Navigate to search
  await page.goto(
    `https://www.zepto.com/search?query=${encodeURIComponent(query)}`,
    { waitUntil: "domcontentloaded" }
  );
  await page.waitForTimeout(2500);

  // Extract products
  return await page.evaluate((limit) => {
    const products = [];
    const cards = document.querySelectorAll('a[href*="/pn/"]');

    cards.forEach((card, i) => {
      if (i >= limit) return;

      const img = card.querySelector("img[alt]");
      const priceEl = card.querySelector(
        '[data-slot-id="EdlpPrice"] span:first-child'
      );
      const origPriceEl = card.querySelector(
        '[data-slot-id="EdlpPrice"] span:last-child'
      );
      const nameEl = card.querySelector('[data-slot-id="ProductName"]');
      const sizeEl = card.querySelector('[data-slot-id="PackSize"]');
      const addBtn = card.querySelector("button");

      products.push({
        name: nameEl?.textContent || img?.alt || "Unknown",
        price: priceEl?.textContent || "",
        originalPrice: origPriceEl?.textContent || "",
        size: sizeEl?.textContent || "",
        inCart: !addBtn?.textContent?.includes("ADD"),
        href: card.href,
        index: i,
      });
    });

    return products;
  }, limit);
}
```

## Add Item to Cart

```javascript
async function addToCart(page, query, productIndex = 0) {
  // Search first
  await page.goto(
    `https://www.zepto.com/search?query=${encodeURIComponent(query)}`,
    { waitUntil: "domcontentloaded" }
  );
  await page.waitForTimeout(2500);

  // Find product and ADD button
  const products = page.locator('a[href*="/pn/"]');
  const product = products.nth(productIndex);

  if ((await product.count()) === 0) {
    return { success: false, error: "NO_PRODUCTS_FOUND" };
  }

  // Check if ADD button exists (not already in cart)
  const addBtn = product.locator('button:has-text("ADD")');

  if ((await addBtn.count()) === 0) {
    // Already in cart - has quantity controls instead
    return { success: true, alreadyInCart: true };
  }

  // Click ADD
  await addBtn.click();
  await page.waitForTimeout(1200);

  // Verify
  const cartCount = await page
    .locator('[data-testid="cart-items-number"]')
    .textContent()
    .catch(() => "0");

  return {
    success: true,
    cartCount: parseInt(cartCount),
    product: await product.locator("img").first().getAttribute("alt"),
  };
}
```

## Get Cart Contents

```javascript
async function getCart(page) {
  // Open cart
  await page.goto("https://www.zepto.com/?cart=open", {
    waitUntil: "domcontentloaded",
  });
  await page.waitForTimeout(2500);

  // Extract items (items in cart have Decrease button)
  const items = await page.evaluate(() => {
    const results = [];
    const seen = new Set();

    document
      .querySelectorAll(
        '[aria-label*="Decrease"], button[aria-label*="Decrease quantity"]'
      )
      .forEach((btn) => {
        // Navigate up to find product container
        let parent = btn.closest('a[href*="/pn/"]');
        if (!parent) {
          parent =
            btn.parentElement?.parentElement?.parentElement?.parentElement;
        }
        if (!parent) return;

        const img = parent.querySelector("img[alt]");
        const name =
          img?.alt ||
          parent.querySelector('[data-slot-id="ProductName"]')?.textContent ||
          "Unknown";

        if (seen.has(name)) return;
        seen.add(name);

        const priceEl = parent.querySelector(
          '[data-slot-id="EdlpPrice"] span:first-child'
        );
        const qtyEl = btn.parentElement?.querySelector("span[data-size]");

        results.push({
          name,
          price: priceEl?.textContent || "",
          quantity: parseInt(qtyEl?.textContent || "1"),
        });
      });

    return results;
  });

  // Extract totals from page text
  const pageText = await page.evaluate(() => document.body.innerText);
  const totalMatch = pageText.match(/To Pay\s*₹(\d+)/);
  const savingsMatch = pageText.match(/saved ₹(\d+)/i);
  const itemCountEl = await page
    .locator('[data-testid="cart-items-number"]')
    .textContent()
    .catch(() => "0");

  return {
    items,
    itemCount: parseInt(itemCountEl),
    total: totalMatch ? `₹${totalMatch[1]}` : null,
    savings: savingsMatch ? `₹${savingsMatch[1]}` : null,
  };
}
```

## Complete Order Flow

```javascript
async function orderItems(page, items, addressType = "home") {
  const results = {
    addressSelected: false,
    itemsAdded: [],
    itemsFailed: [],
    cart: null,
  };

  // Step 1: Select address
  results.addressSelected = await selectAddress(page, addressType);

  // Step 2: Add each item
  for (const item of items) {
    try {
      const result = await addToCart(page, item);
      if (result.success) {
        results.itemsAdded.push({ query: item, ...result });
      } else {
        results.itemsFailed.push({ query: item, error: result.error });
      }
    } catch (err) {
      results.itemsFailed.push({ query: item, error: err.message });
    }
  }

  // Step 3: Get final cart
  results.cart = await getCart(page);

  return results;
}
```

## Usage Examples

### Add Single Item

```javascript
// Navigate and setup
await page.goto("https://www.zepto.com/");
await page.waitForTimeout(2000);

// Select address first (required!)
await selectAddress(page, "home");

// Add item
const result = await addToCart(page, "monster energy");
console.log(result);
// { success: true, cartCount: 1, product: "Monster Energy Drink" }
```

### Add Multiple Items

```javascript
const items = ["monster energy", "greek yogurt", "protein bar"];
const result = await orderItems(page, items, "home");

console.log(`Added: ${result.itemsAdded.length}`);
console.log(`Failed: ${result.itemsFailed.length}`);
console.log(`Cart total: ${result.cart.total}`);
```

### Search and Select Specific Product

```javascript
// Search
const products = await searchProducts(page, "energy drink", 10);

// Find specific product
const monster = products.find(p => 
  p.name.toLowerCase().includes("monster")
);

if (monster) {
  await addToCart(page, "monster energy", monster.index);
}
```
