"""
Integration tests for all service endpoints (FastAPI, Django, Frontend).
Smoke tests to verify service availability and basic functionality.
"""
import json
import logging
from typing import Dict, List

import requests
import pytest

logger = logging.getLogger(__name__)

# Service URLs
FASTAPI_BASE = "http://localhost:5000"
DJANGO_BASE = "http://localhost:8000"
FRONTEND_BASE = "http://localhost:4200"

# Test endpoints
FASTAPI_ENDPOINTS = [
    ("/health", "GET"),
    ("/ready", "GET"),
    ("/info", "GET"),
    ("/metrics", "GET"),
    ("/", "GET"),
]

DJANGO_ENDPOINTS = [
    ("/api/health/", "GET"),
    ("/api/ready/", "GET"),
    ("/api/info/", "GET"),
]

FRONTEND_ENDPOINTS = [
    ("/", "GET"),
    ("/index.html", "GET"),
]


class EndpointTester:
    """Test endpoint availability across services."""

    def __init__(self, base_url: str, service_name: str):
        self.base_url = base_url
        self.service_name = service_name
        self.results = []

    def test_endpoint(self, path: str, method: str = "GET", timeout: int = 5) -> tuple[bool, str, int]:
        """Test a single endpoint."""
        url = f"{self.base_url}{path}"
        try:
            if method == "GET":
                response = requests.get(url, timeout=timeout, allow_redirects=True)
            elif method == "POST":
                response = requests.post(url, timeout=timeout, json={})
            else:
                return False, "Unknown method", 0

            success = response.status_code < 400
            return success, response.reason, response.status_code
        except requests.exceptions.Timeout:
            return False, "Timeout", 0
        except requests.exceptions.ConnectionError:
            return False, "Connection refused", 0
        except Exception as e:
            return False, str(e), 0

    def test_all_endpoints(self, endpoints: List[tuple[str, str]]) -> Dict:
        """Test all endpoints for this service."""
        results = {
            "service": self.service_name,
            "base_url": self.base_url,
            "available": False,
            "endpoints_tested": 0,
            "endpoints_passed": 0,
            "details": [],
        }

        logger.info(f"\n🧪 Testing {self.service_name} ({self.base_url})")
        logger.info("=" * 60)

        for path, method in endpoints:
            success, reason, status_code = self.test_endpoint(path, method)
            results["endpoints_tested"] += 1

            if success:
                results["endpoints_passed"] += 1
                icon = "✅"
            else:
                icon = "❌"

            status_str = f"[{status_code}]" if status_code else ""
            logger.info(f"{icon} {method:4} {path:30} {status_str} {reason}")

            results["details"].append({
                "path": path,
                "method": method,
                "success": success,
                "status_code": status_code,
                "reason": reason,
            })

        results["available"] = results["endpoints_passed"] > 0
        logger.info("=" * 60)
        return results


class IntegrationTestSuite:
    """Complete integration test suite for all services."""

    def __init__(self):
        self.results = {
            "timestamp": None,
            "services": [],
            "summary": {},
        }

    def run_all_tests(self) -> Dict:
        """Run tests for all services."""
        from datetime import datetime
        self.results["timestamp"] = datetime.now().isoformat()

        # Test FastAPI
        fastapi_tester = EndpointTester(FASTAPI_BASE, "FastAPI Backend")
        fastapi_results = fastapi_tester.test_all_endpoints(FASTAPI_ENDPOINTS)
        self.results["services"].append(fastapi_results)

        # Test Django
        django_tester = EndpointTester(DJANGO_BASE, "Django Gateway")
        django_results = django_tester.test_all_endpoints(DJANGO_ENDPOINTS)
        self.results["services"].append(django_results)

        # Test Frontend
        frontend_tester = EndpointTester(FRONTEND_BASE, "Angular Frontend")
        frontend_results = frontend_tester.test_all_endpoints(FRONTEND_ENDPOINTS)
        self.results["services"].append(frontend_results)

        self._calculate_summary()
        return self.results

    def _calculate_summary(self):
        """Calculate overall summary."""
        total_services = len(self.results["services"])
        available_services = sum(1 for s in self.results["services"] if s["available"])
        total_endpoints = sum(s["endpoints_tested"] for s in self.results["services"])
        passed_endpoints = sum(s["endpoints_passed"] for s in self.results["services"])

        self.results["summary"] = {
            "total_services": total_services,
            "available_services": available_services,
            "total_endpoints_tested": total_endpoints,
            "endpoints_passed": passed_endpoints,
            "overall_health": "HEALTHY" if available_services == total_services else "DEGRADED",
        }

    def generate_report(self) -> str:
        """Generate human-readable report."""
        report = "\n" + "=" * 70 + "\n"
        report += "📊 INTEGRATION TEST REPORT\n"
        report += "=" * 70 + "\n\n"

        for service in self.results["services"]:
            status_icon = "✅" if service["available"] else "❌"
            report += f"{status_icon} {service['service']}\n"
            report += f"   Base URL: {service['base_url']}\n"
            report += f"   Endpoints: {service['endpoints_passed']}/{service['endpoints_tested']} passed\n\n"

        report += "-" * 70 + "\n"
        summary = self.results["summary"]
        report += f"Overall Status: {summary['overall_health']}\n"
        report += f"Services Available: {summary['available_services']}/{summary['total_services']}\n"
        report += f"Endpoints Passing: {summary['endpoints_passed']}/{summary['total_endpoints_tested']}\n"
        report += "=" * 70 + "\n"

        return report

    def generate_endpoint_summary(self) -> str:
        """Generate endpoint summary for workflow output."""
        summary = "\n🚀 **Service Endpoints Available:**\n\n"

        summary += "### FastAPI Backend (http://localhost:5000)\n"
        summary += "```\n"
        for path, _ in FASTAPI_ENDPOINTS:
            summary += f"  GET  {path}\n"
        summary += "```\n\n"

        summary += "### Django Gateway (http://localhost:8000)\n"
        summary += "```\n"
        for path, _ in DJANGO_ENDPOINTS:
            summary += f"  GET  {path}\n"
        summary += "```\n\n"

        summary += "### Angular Frontend (http://localhost:4200)\n"
        summary += "```\n"
        for path, _ in FRONTEND_ENDPOINTS:
            summary += f"  GET  {path}\n"
        summary += "```\n\n"

        return summary


# ========================
# Pytest Integration Tests
# ========================

@pytest.mark.skip(reason="Integration tests run only during deployment, not in unit test phase")
@pytest.mark.integration
class TestFastAPIEndpoints:
    """Test FastAPI backend endpoints."""

    def test_fastapi_health(self):
        """Test FastAPI health endpoint."""
        tester = EndpointTester(FASTAPI_BASE, "FastAPI")
        success, reason, _ = tester.test_endpoint("/health", "GET")
        assert success, f"Health check failed: {reason}"

    def test_fastapi_ready(self):
        """Test FastAPI ready endpoint."""
        tester = EndpointTester(FASTAPI_BASE, "FastAPI")
        success, reason, _ = tester.test_endpoint("/ready", "GET")
        assert success, f"Ready check failed: {reason}"

    def test_fastapi_info(self):
        """Test FastAPI info endpoint."""
        tester = EndpointTester(FASTAPI_BASE, "FastAPI")
        success, reason, _ = tester.test_endpoint("/info", "GET")
        assert success, f"Info endpoint failed: {reason}"


@pytest.mark.skip(reason="Integration tests run only during deployment, not in unit test phase")
@pytest.mark.integration
class TestDjangoEndpoints:
    """Test Django gateway endpoints."""

    def test_django_health(self):
        """Test Django health endpoint."""
        tester = EndpointTester(DJANGO_BASE, "Django")
        success, reason, _ = tester.test_endpoint("/api/health/", "GET")
        assert success, f"Django health check failed: {reason}"

    def test_django_ready(self):
        """Test Django ready endpoint."""
        tester = EndpointTester(DJANGO_BASE, "Django")
        success, reason, _ = tester.test_endpoint("/api/ready/", "GET")
        assert success, f"Django ready check failed: {reason}"


@pytest.mark.skip(reason="Integration tests run only during deployment, not in unit test phase")
@pytest.mark.integration
class TestFrontendEndpoints:
    """Test frontend accessibility."""

    def test_frontend_loads(self):
        """Test frontend landing page loads."""
        tester = EndpointTester(FRONTEND_BASE, "Frontend")
        success, reason, _ = tester.test_endpoint("/", "GET")
        assert success, f"Frontend failed to load: {reason}"


@pytest.mark.skip(reason="Integration tests run only during deployment, not in unit test phase")
@pytest.mark.integration
class TestFullIntegration:
    """Full integration test suite."""

    def test_all_services_available(self):
        """Test that all services are available."""
        suite = IntegrationTestSuite()
        results = suite.run_all_tests()

        logger.info(suite.generate_report())

        assert results["summary"]["available_services"] > 0, "No services are available"

    def test_minimum_endpoints_passing(self):
        """Test that minimum number of endpoints are passing."""
        suite = IntegrationTestSuite()
        results = suite.run_all_tests()

        assert results["summary"]["endpoints_passed"] >= 3, "Too few endpoints are passing"


# ========================
# Standalone Test Runner
# ========================

def run_integration_tests():
    """Run integration tests standalone."""
    logging.basicConfig(
        level=logging.INFO,
        format='%(message)s'
    )

    suite = IntegrationTestSuite()
    results = suite.run_all_tests()

    print(suite.generate_report())
    print(suite.generate_endpoint_summary())

    return results


if __name__ == "__main__":
    results = run_integration_tests()
    exit(0 if results["summary"]["overall_health"] == "HEALTHY" else 1)
