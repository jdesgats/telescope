--- cqueues wrapper for telescope.
-- <a href="http://25thandclement.com/~william/projects/cqueues.html">cqueues</a>
-- is an  embeddable, asynchronous networking, threading, and notification
-- framework for Lua. This module contains a few helper functions  to easliy
-- write tests running inside a cqueues controller.
--
-- This module requires the <tt>cqueues</tt> module to be installed in the Lua
-- path.
--
-- @class module
-- @module 'telescope.cqueues'

local compat_env = require 'telescope.compat_env'
local cqueues = require 'cqueues'

local getfenv = _G.getfenv or compat_env.getfenv
local setfenv = _G.setfenv or compat_env.setfenv

--- Wrap a function inside a new cqueues controller and runs it.
-- If the function raises an error, it is propagated, so the tests will be
-- correctly marked as error. This function require the controller to be empty
-- when the funciton exits, this is meant to detect job leaks. If the queue is
-- not empty after the function has been called, the test will error.
-- @param f Function to wrap
-- @return Wrapped function
-- @function wrap
local function wrap(f)
  return function()
    local queue = cqueues.new()
    setfenv(f, getfenv(1))
    queue:wrap(function()
      f(queue)
      cqueues.sleep(0.01) -- let other coroutine a chance to properly terminate
      if queue:count() > 1 then
        error('unfinished jobs')
      end
    end)
    local ok, err, ctx, thread = queue:loop()
    if not ok then
      -- assume table errors to be actual telescope assertions errors
      if type(err) == 'table' then error(err) end
      -- otherwise make test fail cleanly
      error({ 'cqueue controller failed: ' .. err, debug.traceback(thread)})
    end
  end
end

--- Runs a test in a new cqueues controller.
-- Equivalent of <tt>test("my test", cq.wrap(function() ... end))</tt>.
-- @param name Test name
-- @param f Function to test
-- @see wrap
-- @function test
local function cqtest(name, f)
  -- find the `test` function in the calling stack
  for i=2, math.huge do
    local env = assert(getfenv(i), 'cannot find describe block')
    if env.test then
      return env.test(name, wrap(f))
    end
  end
end

return {
  wrap = wrap,
  test = cqtest,
}
