-- vim: ts=2:sw=2
local telescope = require "telescope"

describe("The Telescope Test Framework", function()

  local contexts

  context("The Telescope module", function()
    it("should have a 'version' member", function()
      assert_equal("string", type(telescope.version))
    end)
    it("should have a '_VERSION' member", function()
      assert_equal("string", type(telescope._VERSION))
    end)
  end)

  context("Telescope's syntax", function()

    before(function()
      contexts = telescope.load_contexts("spec/fixtures/syntax.lua")
    end)

    context("contexts and tests", function()

      it("should have names", function()
        assert_equal("A context", contexts[1].name)
        assert_equal("A passing test", contexts[3].name)
      end)

      it("should have parents", function()
        for i, c in ipairs(contexts) do
          assert_gte(c.parent, 0)
        end
      end)

      it("should have a parent of 0 when at the top level", function()
        assert_equal("A context", contexts[1].name)
        assert_equal(0, contexts[1].parent)
        assert_equal("A test in the top level", contexts[9].name)
        assert_equal(0, contexts[9].parent)
      end)

    end)

    context("contexts", function()

      it("can have contexts as children", function()
        assert_equal("A nested context", contexts[2].name)
        assert_equal(1, contexts[2].parent)
      end)

      it("can have tests as children", function()
        assert_equal("A nested context", contexts[3].context_name)
        assert_equal("A passing test", contexts[3].name)
      end)

      it("can have a 'before' function", function()
        assert_type(contexts[1].before[1], "function")
      end)

      it("can have an 'after' function", function()
        assert_type(contexts[1].after[1], "function")
      end)

    end)

    context("tests", function()

      it("when pending, should have true for the 'test' field", function()
        assert_equal("A pending test", contexts[7].name)
        assert_true(contexts[7].test)
      end)

      it("when non-pending, should have a function for the 'test' field", function()
        assert_equal("A test that causes an error", contexts[6].name)
        assert_equal("function", type(contexts[6].test))
      end)

    end)

    context("load_context", function()

      it("should accept a function or a path to a module", function()
        func, err = assert(loadfile("spec/fixtures/syntax.lua"))
        contexts = telescope.load_contexts(func)
        -- We don't need to validate the entire thing, that's done in Syntax.
        -- Just make sure that the result is a context.
        assert_equal("A context", contexts[1].name)
        assert_equal("A passing test", contexts[3].name)
      end)

    end)

    context("assertion messages", function()

       it("should return a proper error message", function()
          local success, msg = pcall(assert_equal, "a", "b")
          assert_false(success)
          assert_equal("Assert failed: expected 'a' to be equal to 'b'", msg[1])
       end)

       it("checks error messages in assert_error", function()
          local success, msg = pcall(assert_error_msg, function() error "wrong message" end, "correct message")
          assert_false(success)
          assert_match("expected result to be the error 'correct message', got '.*: wrong message'", msg[1])

          local success, msg = pcall(assert_error_msg, function() end, "correct message")
          assert_false(success)
          assert_match("expected result to be the error 'correct message', got 'no error'", msg[1])

          local success, msg = pcall(assert_error_msg, function() error "correct message" end, "correct message")
          assert_true(success)
       end)

       it("deep compares tables with assert_same", function()
         local success, msg = pcall(assert_same, { foo="bar" }, { foo="bar" })
         assert_true(success)

         local success, msg = pcall(assert_same, math, math)
         assert_true(success)

         local success, msg = pcall(assert_same, { foo="bar" }, { foo="baz" })
         assert_false(success)
         assert_equal([[on key ["foo"]: expected 'bar', got 'baz']], msg[1])

         local success, msg = pcall(assert_same, { foo="bar" }, { foo="bar", extra=42 })
         assert_false(success)
         assert_equal([[on key ["extra"]: unexpected value (42)]], msg[1])

         local success, msg = pcall(assert_same, { foo="bar", missing=true }, { foo="bar" })
         assert_false(success)
         assert_equal([[on key ["missing"]: expected a value (true), got nil]], msg[1])

         -- deeply nested
         local success, msg = pcall(assert_same, { foo = { bar = { baz = {42} } } }, { foo = { bar = { baz = {"fail"} } } })
         assert_false(success)
         assert_equal([[on key ["foo"]["bar"]["baz"][1]: expected '42', got 'fail']], msg[1])
       end)
    end)

 end)

end)
