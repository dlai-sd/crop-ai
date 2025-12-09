"""
OpenAPI Schema Extractor - Dynamically generates endpoint documentation from FastAPI schema.
"""
import json
import logging
from typing import Dict, List, Optional
from urllib.parse import urljoin

import requests

logger = logging.getLogger(__name__)


class OpenAPIExtractor:
    """Extract and format endpoint information from OpenAPI schema."""

    def __init__(self, openapi_url: str = "http://localhost:5000/openapi.json"):
        """Initialize extractor with OpenAPI endpoint URL."""
        self.openapi_url = openapi_url
        self.schema: Optional[Dict] = None
        self.endpoints: List[Dict] = []

    def fetch_schema(self) -> bool:
        """Fetch OpenAPI schema from FastAPI."""
        try:
            response = requests.get(self.openapi_url, timeout=5)
            response.raise_for_status()
            self.schema = response.json()
            logger.info(f"✅ Fetched OpenAPI schema from {self.openapi_url}")
            return True
        except requests.exceptions.ConnectionError:
            logger.error(f"❌ Cannot connect to {self.openapi_url}")
            return False
        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Failed to fetch schema: {e}")
            return False

    def parse_endpoints(self) -> List[Dict]:
        """Parse endpoints from OpenAPI schema."""
        if not self.schema:
            return []

        endpoints = []
        paths = self.schema.get("paths", {})
        base_url = self.openapi_url.replace("/openapi.json", "")

        for path, methods in paths.items():
            for method, details in methods.items():
                if method.lower() in ["get", "post", "put", "delete", "patch"]:
                    endpoint = {
                        "path": path,
                        "method": method.upper(),
                        "url": urljoin(base_url, path),
                        "summary": details.get("summary", ""),
                        "description": details.get("description", ""),
                        "tags": details.get("tags", []),
                        "parameters": details.get("parameters", []),
                        "requestBody": details.get("requestBody", None),
                    }
                    endpoints.append(endpoint)

        self.endpoints = sorted(endpoints, key=lambda x: (x["path"], x["method"]))
        logger.info(f"✅ Parsed {len(self.endpoints)} endpoints")
        return self.endpoints

    def generate_markdown(self) -> str:
        """Generate markdown documentation from endpoints."""
        if not self.endpoints:
            return "No endpoints found."

        md = "# FastAPI Endpoints Documentation\n\n"
        md += f"**Base URL:** `http://localhost:5000`\n\n"

        # Group by tags
        by_tag = {}
        for endpoint in self.endpoints:
            tags = endpoint.get("tags") or ["General"]
            for tag in tags:
                if tag not in by_tag:
                    by_tag[tag] = []
                by_tag[tag].append(endpoint)

        for tag in sorted(by_tag.keys()):
            md += f"## {tag}\n\n"
            md += "| Method | Path | Summary |\n"
            md += "|--------|------|----------|\n"

            for endpoint in by_tag[tag]:
                method = f"`{endpoint['method']}`"
                path = f"`{endpoint['path']}`"
                summary = endpoint.get("summary", endpoint.get("description", "N/A"))[:80]
                md += f"| {method} | {path} | {summary} |\n"

            md += "\n"

        return md

    def generate_endpoint_catalog(self) -> str:
        """Generate a simple endpoint catalog."""
        if not self.endpoints:
            return "No endpoints available."

        catalog = "## 📡 FastAPI Endpoint Catalog\n\n"

        for endpoint in self.endpoints:
            method_color = {
                "GET": "🟢",
                "POST": "🔵",
                "PUT": "🟠",
                "DELETE": "🔴",
                "PATCH": "🟣",
            }.get(endpoint["method"], "⚪")

            catalog += f"- {method_color} **{endpoint['method']}** `{endpoint['path']}`"
            if endpoint.get("summary"):
                catalog += f" — {endpoint['summary']}"
            catalog += "\n"

        return catalog

    def get_endpoint_urls(self) -> Dict[str, List[str]]:
        """Get all endpoint URLs grouped by method."""
        urls_by_method = {}
        for endpoint in self.endpoints:
            method = endpoint["method"]
            if method not in urls_by_method:
                urls_by_method[method] = []
            urls_by_method[method].append(endpoint["path"])
        return urls_by_method

    def test_endpoint_availability(self, endpoint: Dict) -> tuple[bool, str]:
        """Test if an endpoint is available."""
        try:
            if endpoint["method"] == "GET":
                response = requests.get(endpoint["url"], timeout=3)
            elif endpoint["method"] == "POST":
                # For POST, just test if endpoint exists (may require body)
                response = requests.options(endpoint["url"], timeout=3)
            else:
                return True, "Skipped"

            if response.status_code in [200, 201, 204, 405, 422]:  # 405 = method not allowed
                return True, f"Status: {response.status_code}"
            else:
                return False, f"Status: {response.status_code}"
        except requests.exceptions.Timeout:
            return False, "Timeout"
        except requests.exceptions.ConnectionError:
            return False, "Connection failed"
        except Exception as e:
            return False, str(e)


def main():
    """Test the extractor."""
    extractor = OpenAPIExtractor()

    if not extractor.fetch_schema():
        logger.error("Failed to fetch schema. Is FastAPI running on http://localhost:5000?")
        return

    endpoints = extractor.parse_endpoints()

    if endpoints:
        print("\n" + "=" * 60)
        print(extractor.generate_endpoint_catalog())
        print("=" * 60)

        print("\n### Testing Endpoint Availability:\n")
        for endpoint in endpoints[:5]:  # Test first 5
            available, status = extractor.test_endpoint_availability(endpoint)
            icon = "✅" if available else "❌"
            print(f"{icon} {endpoint['method']} {endpoint['path']} — {status}")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    main()
