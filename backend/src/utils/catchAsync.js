module.exports = fn => {
  return (req, res, next) => {
    if (typeof next !== 'function') {
      console.error('CRITICAL: next is not a function in catchAsync wrapper!');
      console.error('req.method:', req.method);
      console.error('req.url:', req.url);
    }
    fn(req, res, next).catch(next);
  };
};
